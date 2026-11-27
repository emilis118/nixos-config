{
  config,
  pkgs,
  lib,
  ...
}: let
  # lxask (github.com/arxhr007/lxask): ask for a shell command in plain words,
  # answered offline by a small local model and checked against the man pages.
  #
  #   lxask "biggest folders here"   answer + an explanation of every part
  #   lxask --explain "cmd"          take a command you already have apart
  #   Ctrl+G at the zsh prompt       the typed words become the command
  #   mod+Shift+a                    the popup below
  #   Ctrl+Enter in the cheat tab    the popup, with what you typed (mod+/)
  #
  # Upstream ships a prebuilt binary and an install.sh that puts everything in
  # ~/.local; here the release files are fetched by nix instead, so `lxask
  # --upgrade` is switched off: bump `version` and the hashes (the release's
  # SHA256SUMS lists them all, in the hex form fetchurl takes) to upgrade.
  version = "1.5.8";
  release = "https://github.com/arxhr007/lxask/releases/download/v${version}";
  fetch = name: sha256:
    pkgs.fetchurl {
      url = "${release}/${name}";
      inherit sha256;
    };

  # Two x86 builds: -v3 (AVX2+FMA, since ~2015) is the faster one, the plain
  # one covers older CPUs. Both are kept and the wrapper picks at run time,
  # the way install.sh would, so one config works on every host.
  # Only glibc is linked, which autoPatchelf points at the store's.
  bins = pkgs.stdenv.mkDerivation {
    pname = "lxask-bin";
    inherit version;
    dontUnpack = true;
    dontStrip = true;
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    installPhase = ''
      install -Dm755 ${fetch "lxask-x86_64-v3" "27b94d8fe680701b3bd33486d8281930d0b0fe525ba4fb0dfde2be375af52eec"} $out/libexec/lxask-x86_64-v3
      install -Dm755 ${fetch "lxask-x86_64" "7c54f3621e9c9c704cacaed227b6f952ed83d3deb790fd8cad92d2d6478c13cc"} $out/libexec/lxask-x86_64
    '';
  };

  # ~1.1 GB, the model being most of it: the model, its two adapters (for
  # "without X" requests and for precision), the encoder and the docs index.
  data = pkgs.linkFarm "lxask-data-${version}" {
    "model.gguf" = fetch "lxask-round4-Q4_K_M.gguf" "023ee206403c7fc96a9be13e1aec761dd798d73c6d2f876a6c09c392dbf9cbc5";
    "restrict.gguf" = fetch "restrict-round4.gguf" "e77b3d86aab83aedf1a464993599c4b503d59d80b3fa7147b420221c214c8549";
    "precision.gguf" = fetch "precision-round4.gguf" "e94e62eddea0ced6d16a2cafbba63b8545509d5c87bd5ffa8b3e497325e47de4";
    "embed.gguf" = fetch "embed.gguf" "ec38e8da142596baa913124ae50550de284b6916bf59577ef2f0cb9660c2f514";
    "docs.sqlite" = fetch "docs.sqlite" "31161014d63d175a7b7f01cdb63e565410bc5100b417b9278c09307a6daeaa52";
  };

  # $LXASK_HOME stays the default ~/.local/share/lxask, which has to be
  # writable (the server's socket, last.json, the feedback log); only the
  # read-only files are pointed into the store.
  #
  # It checks options against this machine's man pages, but only looks in
  # $MANPATH and /usr/share/man, and NixOS has neither: hence the profile
  # man dirs. Only this process tree sees the MANPATH, not your shell.
  lxask = pkgs.writeShellScriptBin "lxask" ''
    case "''${1:-}" in
    --upgrade)
      echo "lxask: installed by nix (home-manager/features/lxask.nix); bump the version there" >&2
      exit 1
      ;;
    esac

    if grep -qw avx2 /proc/cpuinfo && grep -qw fma /proc/cpuinfo; then
      exe=${bins}/libexec/lxask-x86_64-v3
    else
      exe=${bins}/libexec/lxask-x86_64
    fi

    export LXASK_MODEL=${data}/model.gguf
    export LXASK_ADAPTER=${data}/restrict.gguf
    export LXASK_PRECISION=${data}/precision.gguf
    export LXASK_EMBED_MODEL=${data}/embed.gguf
    export LXASK_INDEX=${data}/docs.sqlite
    export MANPATH="''${MANPATH:+$MANPATH:}/etc/profiles/per-user/$USER/share/man:$HOME/.nix-profile/share/man:/run/current-system/sw/share/man"
    # gzip: the man pages are .gz
    export PATH="$PATH:${pkgs.gzip}/bin"
    exec -a lxask "$exe" "$@"
  '';

  # What Ctrl+G sources, rendered once at build time instead of running
  # lxask on every shell start.
  shellInit = pkgs.runCommand "lxask-zsh-init" {} ''
    ${lxask}/bin/lxask --shell-init zsh > $out
  '';

  lxaskHome = "${config.xdg.dataHome}/lxask";

  # i3 window class, for the for_window rule and the toggle check
  class = "lxask-popup";

  # What runs inside the popup: ask, show the answer, then either
  #   Enter          copy the command and close
  #   type + Enter   ask something else, in the same window
  #   Esc / Ctrl+D   close
  # The command is taken from last.json, which lxask writes after every answer
  # (only when this question was the one answered, so an error or an
  # "ask back" doesn't hand you the previous answer's command). A multi-step
  # answer is joined with &&, as `lxask --command-only` does.
  lxaskAsk = pkgs.writeShellApplication {
    name = "lxask-ask";
    runtimeInputs = [lxask pkgs.jq pkgs.xclip pkgs.util-linux pkgs.coreutils];
    bashOptions = ["nounset" "pipefail"];
    text = ''
      dim=$'\e[2m' bold=$'\e[1m' off=$'\e[0m'
      q=''${1:-}
      # up-arrow recalls earlier questions in this window
      HISTFILE=/dev/null
      set -o history

      while :; do
        if [ -z "$q" ]; then
          read -e -r -p "ask: " q || exit 0
          [ -n "$q" ] || exit 0
        fi
        history -s "$q"

        printf '%s> %s%s\n\n%sthinking…%s' "$bold" "$q" "$off" "$dim" "$off"
        out=$(lxask "$q" 2>&1)
        code=$?
        printf '\r\e[K%s\n' "$out"

        cmd=""
        if [ "$code" -eq 0 ]; then
          cmd=$(jq -r --arg q "$q" '
            select(.question == $q)
            | [.steps[].command | select(. != null and . != "")]
            | join(" && ")' "${lxaskHome}/last.json" 2>/dev/null) || cmd=""
        fi

        echo
        if [ -n "$cmd" ]; then
          printf '%senter: copy & close   or type another question   esc: close%s\n' "$dim" "$off"
        else
          printf '%stype another question   esc: close%s\n' "$dim" "$off"
        fi
        read -e -r -p "> " next || exit 0

        if [ -z "$next" ]; then
          # setsid: xclip stays behind to own the clipboard, and has to
          # outlive this terminal closing a moment later
          [ -n "$cmd" ] && printf '%s' "$cmd" | setsid -f xclip -selection clipboard >/dev/null 2>&1
          exit 0
        fi
        q=$next
        clear
      done
    '';
  };

  # Toggle like claude-popup: a second mod+Shift+a closes it. Given a
  # question (from the cheat tab), any open popup is replaced by a new one
  # answering it.
  lxaskPopup = pkgs.writeShellApplication {
    name = "lxask-popup";
    runtimeInputs = [pkgs.jq pkgs.coreutils];
    text = ''
      if i3-msg -t get_tree \
        | jq -e --arg c ${class} '.. | objects | select(.window_properties?.class == $c)' >/dev/null; then
        i3-msg "[class=\"^${class}$\"] kill" >/dev/null
        [ $# -gt 0 ] || exit 0
      fi

      exec ${pkgs.alacritty}/bin/alacritty \
        --class ${class},${class} \
        --title "lxask" \
        -o 'window.opacity=0.95' \
        -o 'window.padding.x=12' \
        -o 'window.padding.y=10' \
        -o 'colors.primary.background="${config.theme.palette.bg}"' \
        -o 'keyboard.bindings=[{key="Escape",action="Quit"}]' \
        -e ${lxaskAsk}/bin/lxask-ask "$@"
    '';
  };
in {
  imports = [./theme.nix];

  home.packages = [lxask lxaskPopup];

  # serve = auto: the first question starts a server in the background that
  # keeps the model loaded (~1.3 GB) and stops after 30 idle minutes, so the
  # first answer takes a few seconds and later ones about two.
  # update_check: upgrades come from here, not from `lxask --upgrade`.
  xdg.dataFile."lxask/settings".text = ''
    serve = auto
    update_check = off
  '';

  # Ctrl+G turns the plain words on the prompt into the command. A command
  # lxask has doubts about lands commented out, so Enter on it must be a no-op
  # rather than "command not found: #".
  programs.zsh.initContent = lib.mkAfter ''
    setopt interactivecomments
    source ${shellInit}
  '';

  xsession.windowManager.i3 = {
    config.keybindings."Mod1+Shift+a" = "exec --no-startup-id lxask-popup";

    # mkAfter: after i3-profile's `[class=".*"] border none`, see claude-popup
    extraConfig = lib.mkAfter ''
      for_window [class="^${class}$"] floating enable, sticky enable, border pixel 2, resize set 50 ppt 40 ppt, move position center, focus
    '';
  };
}
