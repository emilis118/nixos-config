{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.passwordStore;

  # The store is a sops file encrypted to the admin key only (see .sops.yaml).
  # Nothing here reads it at build time — it is decrypted on demand with the
  # key in ~/.config/sops/age/keys.txt, so editing an entry takes effect
  # immediately without a rebuild.
  #
  # Shape:
  #   github:
  #     username: emilis118
  #     password: hunter2
  #     url: https://github.com
  #     notes: recovery codes are in the safe
  pwLib = ''
    export PATH=${makeBinPath [pkgs.sops pkgs.jq pkgs.xclip pkgs.clipmenu pkgs.coreutils]}:$PATH

    store="''${PASSWORD_STORE_FILE:-${cfg.file}}"

    die() {
      echo "pw: $*" >&2
      exit 1
    }

    decrypt() {
      [ -f "$store" ] || die "no store at $store (create it: SOPS-SETUP.md step 6)"
      sops -d --output-type json "$store" 2>/dev/null ||
        die "could not decrypt $store - is your admin key in ~/.config/sops/age/keys.txt?"
    }

    # Copy to the clipboard, then wipe it so a password doesn't sit there.
    # clipmenud is paused across the copy, otherwise the password would be
    # sitting in the clipboard history long after this cleared the clipboard
    # itself. Both calls are best-effort: clipmenu may not be running.
    #
    # xclip stays resident to own the selection, so its output has to be
    # detached: in rofi script mode (the "pw" tab) rofi reads this script's
    # stdout until EOF, and an xclip holding that pipe open freezes the whole
    # rofi window until the clear below takes the selection away from it.
    clip() {
      clipctl disable >/dev/null 2>&1 || true
      printf '%s' "$1" | xclip -selection clipboard >/dev/null 2>&1
      (
        # long enough for clipmenud to have skipped this change
        sleep 2
        clipctl enable >/dev/null 2>&1 || true
        sleep ${toString (cfg.clearAfter - 2)}
        # only clear if it is still our value, so a later copy isn't eaten
        if [ "$(xclip -selection clipboard -o 2>/dev/null)" = "$1" ]; then
          printf "" | xclip -selection clipboard
        fi
      ) >/dev/null 2>&1 &
    }
  '';

  pw = pkgs.writeShellScriptBin "pw" ''
    set -euo pipefail
    ${pwLib}

    usage() {
      cat >&2 <<'USAGE'
    usage:
      pw                 pick an entry (rofi), copy its password
      pw <entry>         copy <entry>'s password to the clipboard
      pw -u <entry>      copy the username instead
      pw show <entry>    print every field of <entry>
      pw list            list entry names
      pw edit            open the store in $EDITOR through sops
    USAGE
      exit 1
    }

    # $1 entry, $2 field. Note the explicit `|| exit`: `die` inside a command
    # substitution only kills the subshell, so the value has to be captured
    # and checked here rather than passed straight to clip.
    copy() {
      local json val
      json=$(decrypt) || exit 1
      val=$(printf '%s' "$json" | jq -er --arg e "$1" --arg f "$2" '.[$e][$f] // empty') ||
        die "no $2 for '$1'"
      clip "$val"
      echo "copied $2 for $1 (clears in ${toString cfg.clearAfter}s)"
    }

    case "''${1:-}" in
    "")
      entry=$(decrypt | jq -r 'keys[]' | ${pkgs.rofi}/bin/rofi -dmenu -i -p password) || exit 0
      [ -n "$entry" ] || exit 0
      copy "$entry" password
      ;;
    list | ls) decrypt | jq -r 'keys[]' ;;
    edit) exec sops "$store" ;;
    show)
      [ $# -eq 2 ] || usage
      decrypt | jq -er --arg e "$2" '.[$e] // empty | to_entries[] | "\(.key): \(.value)"' ||
        die "no such entry: $2"
      ;;
    -u)
      [ $# -eq 2 ] || usage
      copy "$2" username
      ;;
    -h | --help) usage ;;
    *)
      [ $# -eq 1 ] || usage
      copy "$1" password
      ;;
    esac
  '';

  # rofi script mode, same shape as the bookmarks/remote tabs in rofi.nix:
  # listed with no arguments, re-invoked with the chosen line as $1.
  # Selecting an entry copies its password; printing nothing closes rofi.
  rofi-passwords = pkgs.writeShellScriptBin "rofi-passwords" ''
    ${pwLib}

    empty="(no password store yet - see SOPS-SETUP.md)"

    if [ -z "''${1:-}" ]; then
      # a store that isn't set up yet shouldn't make the tab look broken
      entries=$(decrypt 2>/dev/null | jq -r 'keys[]' 2>/dev/null) || entries=""
      if [ -z "$entries" ]; then
        printf '%s\n' "$empty"
      else
        printf '%s\n' "$entries"
      fi
      exit 0
    fi

    [ "$1" != "$empty" ] || exit 0

    pass=$(decrypt | jq -er --arg e "$1" '.[$e].password // empty') || exit 0
    clip "$pass"
  '';
in {
  # A password manager that reuses the sops setup rather than adding a second
  # encrypted store: entries live in secrets/passwords.yaml, encrypted to your
  # admin key, and are read on demand by `pw` or the rofi "pw" tab.
  options.passwordStore = {
    enable = mkEnableOption "the sops-backed password store (`pw`)";

    file = mkOption {
      type = types.str;
      default = "\${FLAKE:-$HOME/00_projects/nixos-config}/secrets/passwords.yaml";
      description = ''
        Path to the encrypted store, expanded by the shell at runtime. It
        points at the working tree rather than the nix store on purpose, so
        `pw edit` and the next `pw` see the same file with no rebuild in
        between.
      '';
    };

    clearAfter = mkOption {
      type = types.int;
      default = 45;
      description = "Seconds before a copied password is wiped from the clipboard.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      pw
      rofi-passwords
      pkgs.sops # also edits the machine secrets: `sops secrets/common.yaml`
      pkgs.age # age-keygen, for the admin key
    ];

    # adds a "pw" tab to the main rofi window (see rofi.nix)
    rofiModes.passwords = mkDefault true;
  };
}
