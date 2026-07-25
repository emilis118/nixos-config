{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.cheatsheet;

  entries = import ./data.nix;

  # One TSV line per entry. Tabs are the only separator, so no field may
  # contain one — data.nix says as much.
  curated =
    pkgs.writeText "cheatsheet.tsv"
    (concatMapStrings (e: "${e.cat}\t${e.syntax}\t${e.desc}\t${e.example or ""}\n") entries);

  # Shared by the CLI and the rofi mode: the curated sheet plus your own
  # notes, which live outside the store so adding one doesn't need a rebuild.
  lib' = ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.xclip pkgs.libnotify pkgs.util-linux pkgs.less pkgs.rofi]}:$PATH

    notes="${cfg.notesFile}"

    ensure_notes() {
      [ -e "$notes" ] && return
      mkdir -p "$(dirname "$notes")"
      cat >"$notes" <<'EOF'
    # Your own cheat sheet. One entry per line, fields separated by TABS:
    #
    #   category<TAB>syntax<TAB>description<TAB>example
    #
    # The example is what gets copied when you pick the entry; leave it empty
    # to copy the syntax instead. Lines starting with # are ignored.
    # No rebuild needed — `cheat` and the rofi tab re-read this every time.
    EOF
    }

    # curated first, then yours; strip comments and blank lines
    all() {
      ensure_notes
      cat ${curated} "$notes" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$'
    }
  '';

  cheat = pkgs.writeShellScriptBin "cheat" ''
    set -uo pipefail
    ${lib'}

    case "''${1:-}" in
    -e | edit)
      ensure_notes
      exec ''${EDITOR:-nvim} "$notes"
      ;;
    -a | add)
      shift
      ensure_notes
      if [ $# -lt 2 ]; then
        echo "usage: cheat add <syntax> <description> [example] [category]" >&2
        exit 1
      fi
      printf '%s\t%s\t%s\t%s\n' "''${4:-note}" "$1" "$2" "''${3:-}" >>"$notes"
      echo "added to $notes"
      ;;
    -h | --help)
      cat >&2 <<'USAGE'
    usage:
      cheat                       print the whole sheet
      cheat <term>                only lines matching <term>
      cheat add SYNTAX DESC [EXAMPLE] [CATEGORY]
                                  add one of your own (category defaults to "note")
      cheat edit                  open your notes file in $EDITOR

    The rofi "cheat" tab shows the same thing; picking a row copies its
    example. Your notes live outside the nix store, so adding one takes
    effect immediately.
    USAGE
      exit 1
      ;;
    "")
      all | sed 's/^/[/; s/\t/]\t/' | column -t -s "$(printf '\t')" | ${cfg.pager}
      ;;
    *)
      all | grep -i -- "$1" | sed 's/^/[/; s/\t/]\t/' | column -t -s "$(printf '\t')"
      ;;
    esac
  '';

  # rofi script mode, same protocol as the bookmarks/remote/pw tabs: listed
  # with no arguments, re-invoked with the chosen row. The row index rides
  # along in ROFI_INFO so the display text can be padded freely.
  rofiCheat = pkgs.writeShellScriptBin "rofi-cheat" ''
    set -uo pipefail
    ${lib'}

    add_label="+        add an entry of your own"

    if [ -z "''${1:-}" ]; then
      printf '\0prompt\x1fcheat\n'
      i=0
      while IFS="$(printf '\t')" read -r c s d _; do
        printf '%-8s %-26s %s\0info\x1f%s\n' "[$c]" "$s" "$d" "$i"
        i=$((i + 1))
      done < <(all)
      printf '%s\0info\x1fadd\n' "$add_label"
      exit 0
    fi

    if [ "''${ROFI_INFO:-}" = "add" ]; then
      # a nested rofi can't run inside this one, so hand it off
      setsid -f ${cheatAdd}/bin/cheat-add >/dev/null 2>&1 </dev/null
      exit 0
    fi

    row=$(all | sed -n "$((ROFI_INFO + 1))p")
    [ -n "$row" ] || exit 0

    syntax=$(printf '%s' "$row" | cut -f2)
    desc=$(printf '%s' "$row" | cut -f3)
    example=$(printf '%s' "$row" | cut -f4)

    # the example is the useful thing to paste; fall back to the syntax
    copy=''${example:-$syntax}
    printf '%s' "$copy" | xclip -selection clipboard
    notify-send -a cheat "$syntax" "$desc

    copied: $copy"
  '';

  # Prompted add, so a new note is three keystrokes from the launcher.
  cheatAdd = pkgs.writeShellScriptBin "cheat-add" ''
    set -uo pipefail
    ${lib'}
    ensure_notes

    ask() { rofi -dmenu -p "$1" -l 0 </dev/null; }

    syntax=$(ask "syntax") || exit 0
    [ -n "$syntax" ] || exit 0
    desc=$(ask "what it does") || exit 0
    example=$(ask "example (optional)") || true
    cat_name=$(ask "category (blank = note)") || true

    printf '%s\t%s\t%s\t%s\n' "''${cat_name:-note}" "$syntax" "$desc" "''${example:-}" >>"$notes"
    notify-send -a cheat "Added to your cheat sheet" "$syntax"
  '';
in {
  # Searchable cheat sheets: a curated set in data.nix (shell, vim, this
  # neovim config, zsh, nix, tmux, i3, and the commands this repo adds) plus
  # your own notes file that needs no rebuild.
  options.cheatsheet = {
    enable = mkEnableOption "cheat sheets in rofi and the `cheat` command" // {default = true;};

    notesFile = mkOption {
      type = types.str;
      default = "${config.xdg.dataHome}/cheatsheet/mine.tsv";
      description = "Your own entries. Plain TSV, outside the store, re-read on every use.";
    };

    pager = mkOption {
      type = types.str;
      default = "less -FRX";
      description = "Pager for a bare `cheat`. -F means short sheets just print.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cheat rofiCheat cheatAdd];

    # adds the "cheat" tab to the main rofi window (see rofi.nix)
    rofiModes.cheat = mkDefault true;

    xdg.desktopEntries.cheatsheet = {
      name = "Cheat sheet";
      exec = "rofi -show cheat";
      icon = "help-contents";
      categories = ["Utility"];
    };
  };
}
