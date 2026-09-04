{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}: let
  cfg = config.rofiModes;
  remminaConnections = config.remmina.connections;

  # Web bookmarks surfaced as a "bookmarks" tab in rofi. Picking one focuses
  # workspace 1 first, so the new tab lands in the Firefox window living
  # there (firefox opens URLs in the most recently focused window).
  # The list is shared with firefox; edit it in bookmarks.nix.
  bookmarks = import ./bookmarks.nix;

  rofi-bookmarks = pkgs.writeShellScriptBin "rofi-bookmarks" ''
    # rofi script mode: listed without arguments, re-invoked with the chosen
    # entry as $1. Printing nothing on selection makes rofi close.
    if [ -z "$1" ]; then
    ${lib.concatMapStrings (b: ''
        printf '%s\0icon\x1f%s\n' ${lib.escapeShellArg b.name} ${lib.escapeShellArg b.icon}
      '')
      bookmarks}  exit 0
    fi

    case "$1" in
    ${lib.concatMapStrings (b: ''
        ${lib.escapeShellArg b.name}) url=${lib.escapeShellArg b.url} ;;
      '')
      bookmarks}  *) exit 0 ;;
    esac

    i3-msg "workspace number 1" >/dev/null 2>&1
    setsid -f firefox --new-tab "$url" >/dev/null 2>&1 </dev/null
  '';

  # Remote-desktop connections surfaced as a "remote" tab, entirely driven by
  # `remmina.connections` (features/remote.nix) so the list is identical on
  # every machine that imports it - no dependence on whatever remmina's own
  # GUI happened to save locally on this particular machine.
  #
  # Selecting one decrypts the password for its username from the sops store
  # (secrets/passwords.yaml, key "rdp-<username>") and hands remmina a
  # one-off "protocol://user:pass@server" URI, so the password never touches
  # disk - only the process argv, same trust level as the "pw" tab's
  # clipboard. Connections sharing a username share one store entry.
  #
  # A failed decrypt or missing entry raises a desktop notification instead
  # of silently doing nothing - the likely cause is that this machine has no
  # admin sops key yet (~/.config/sops/age/keys.txt, see SOPS-SETUP.md step
  # 6: the same key has to be placed on every machine that should be able to
  # decrypt secrets/passwords.yaml, a rebuild alone won't put it there).
  rofi-remmina = pkgs.writeShellScriptBin "rofi-remmina" ''
    # not escapeShellArg: the value is itself a shell expansion
    # ("${FLAKE:-$HOME/...}/secrets/passwords.yaml") that has to run at
    # runtime, same as passwordStore's own pwLib.
    store="${config.passwordStore.file}"

    warn() {
      ${pkgs.libnotify}/bin/notify-send -a remmina "remmina" "$1" 2>/dev/null
    }

    if [ -z "$1" ]; then
      ${lib.concatMapStrings (c: ''
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' \
          ${lib.escapeShellArg "${c.name}  (${c.protocol} ${c.username}@${c.server})"} \
          preferences-desktop-remote-desktop \
          ${lib.escapeShellArg c.name}
      '')
      remminaConnections}
      exit 0
    fi

    [ -n "$ROFI_INFO" ] || exit 0

    case "$ROFI_INFO" in
    ${lib.concatMapStrings (c: ''
        ${lib.escapeShellArg c.name})
          creds=$(${pkgs.sops}/bin/sops -d --output-type json "$store" 2>/dev/null) || {
            warn "couldn't decrypt the password store - is the sops admin key at ~/.config/sops/age/keys.txt on this machine?"
            exit 1
          }
          pass=$(printf '%s' "$creds" | ${pkgs.jq}/bin/jq -er --arg e ${lib.escapeShellArg "rdp-${c.username}"} '.[$e].password // empty') || {
            warn "no 'rdp-${c.username}' entry in the password store (pw edit)"
            exit 1
          }
          uri=$(${pkgs.jq}/bin/jq -rn --arg u ${lib.escapeShellArg c.username} --arg p "$pass" --arg s ${lib.escapeShellArg c.server} \
            '"${c.protocol}://" + ($u|@uri) + ":" + ($p|@uri) + "@" + ($s|@uri)')
          setsid -f ${pkgs.remmina}/bin/remmina -c "$uri" >/dev/null 2>&1 </dev/null
          ;;
      '')
      remminaConnections}
    *) exit 0 ;;
    esac
  '';
in {
  options.rofiModes = {
    remote = lib.mkEnableOption "remmina remote-desktop tab in rofi";
    # the script itself lives in features/passwords.nix, which sets this
    passwords = lib.mkEnableOption "password-store tab in rofi";
    # likewise features/cheatsheet
    cheat = lib.mkEnableOption "cheat-sheet tab in rofi";
    # likewise features/clipboard.nix
    clipboard = lib.mkEnableOption "clipboard-history tab in rofi";
  };

  options.remmina.connections = lib.mkOption {
    type = lib.types.listOf (lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Label shown in the rofi \"remote\" tab.";
        };
        server = lib.mkOption {
          type = lib.types.str;
          description = "Host to connect to.";
        };
        username = lib.mkOption {
          type = lib.types.str;
          description = ''
            Username to connect with. Not secret - only the password is, and
            it's shared by every connection with the same username: add it
            once to secrets/passwords.yaml under `rdp-<username>` (`pw edit`;
            only the `password` field is read) and every connection using
            that login picks it up.
          '';
        };
        protocol = lib.mkOption {
          type = lib.types.str;
          default = "rdp";
          description = ''
            URI scheme remmina connects with. Credentials-in-URI is only
            confirmed to work for "rdp"; other protocols may just ignore
            them and prompt.
          '';
        };
      };
    });
    default = [];
    description = ''
      Remote-desktop connections shown in the rofi "remote" tab - the whole
      tab is generated from this list, with no .remmina file on disk for any
      of them. See rofi-remmina above for how the password reaches remmina
      at connect time.
    '';
  };

  config = {
    programs.rofi = {
      enable = true;
      plugins = with pkgs; [
        rofi-calc # calculator
        # rofi-top removed: it divides by zero while redrawing (SIGFPE) and
        # takes the whole rofi instance down with it, even from other modes.
      ];
      terminal = "${pkgs.alacritty}/bin/alacritty";
      theme = ../../dotfiles/rofi/theme.rasi;
      extraConfig = {
        # Only modes that run inside a single rofi instance belong here.
        # The standalone wrappers (rofi-bluetooth, rofi-screenshot, ...) spawn
        # their own rofi window, so they are exposed as drun entries below.
        modi = lib.concatStringsSep "," (
          [
            "drun"
            "bookmarks:${rofi-bookmarks}/bin/rofi-bookmarks"
            "run"
            "window"
            "ssh"
          ]
          ++ lib.optional cfg.remote "remote:${rofi-remmina}/bin/rofi-remmina"
          ++ lib.optional cfg.passwords "pw:rofi-passwords"
          ++ lib.optional cfg.cheat "cheat:rofi-cheat"
          ++ lib.optional cfg.clipboard "clip:rofi-clipboard"
          ++ [
            "calc"
            "power:rofi-power-menu"
          ]
        );
        show-icons = true;
        icon-theme = "Papirus-Dark";
        sidebar-mode = true; # clickable mode tabs at the bottom

        # Tab / Shift+Tab cycle modes instead of moving the selection
        kb-element-next = "";
        kb-element-prev = "";
        kb-mode-next = "Shift+Right,Control+Tab,Tab";
        kb-mode-previous = "Shift+Left,Control+ISO_Left_Tab,ISO_Left_Tab";

        display-drun = "apps";
        display-bookmarks = "bookmarks";
        display-run = "run";
        display-window = "windows";
        display-ssh = "ssh";
        display-remote = "remote";
        display-pw = "pw";
        display-cheat = "cheat";
        display-clip = "clip";
        display-calc = "calc";
        display-power = "power";
      };
    };

    home.packages = with pkgs; [
      htop # process monitor, replaces rofi-top; its desktop entry opens in alacritty from drun
      rofi-bluetooth
      rofi-screenshot
      rofi-power-menu
      rofi-pulse-select
      todofi-sh
      todo-txt-cli # todofi.sh is only a rofi front-end for `todo.sh`
      networkmanager_dmenu # wifi picker, launched from the polybar wlan icon
      papirus-icon-theme # icons for rofi drun mode
    ];

    # todofi.sh shells out to `todo.sh -d ~/.config/todo/config` for every
    # single operation, and todo.sh hard-fails ("Cannot read configuration
    # file") when that path is missing. Without this file the todo tab opens
    # but is permanently empty and the "add" shortcut silently adds nothing -
    # the failure is invisible because todofi.sh throws stderr away.
    # todo.sh creates TODO_DIR and the .txt files themselves on first run.
    xdg.configFile."todo/config".text = ''
      export TODO_DIR="${config.xdg.dataHome}/todo"
      export TODO_FILE="$TODO_DIR/todo.txt"
      export DONE_FILE="$TODO_DIR/done.txt"
      export REPORT_FILE="$TODO_DIR/report.txt"

      # todofi.sh does its own pango highlighting, so keep todo.sh's ANSI
      # colours out of the strings it parses.
      export TODOTXT_PLAIN=1
      # keep completed items in todo.txt (marked "x ...") instead of moving
      # them to done.txt on the spot, so todofi's active/done view (Super+Tab)
      # has something in it; archive on demand from its help menu.
      export TODOTXT_AUTO_ARCHIVE=0
    '';

    # todofi.sh's built-in EDITOR default is `gedit`; the "open todo.txt" and
    # "see configuration files" actions in its help menu just do nothing when
    # it isn't installed. It's launched from rofi with no terminal attached,
    # so $EDITOR=nvim can't work either - wrap it in one.
    #
    # The shortcut remaps are the other half of the fix. todofi ships on
    # Alt+<key>, but i3's modifier is Mod1 (alt) and X hands a grabbed combo
    # to i3 rather than to the focused window - so stock Alt+d / Alt+p /
    # Alt+c / Alt+h never reach rofi at all, they open drun, clip and calc
    # and move focus left instead.
    #
    # Moving the whole set onto Mod4 (win) keeps every mnemonic letter and
    # sidesteps the alt grabs: i3 only binds Mod4+h/j/k/l (move/resize) and
    # rofi's own Super defaults are just the digits and Super+equal/minus.
    # Help is the one exception - Mod4+h is i3's, so it gets i(nfo).
    xdg.configFile."todofish.conf".text = ''
      EDITOR='${pkgs.alacritty}/bin/alacritty -e nvim'

      SHORTCUT_NEW="Super+a"
      SHORTCUT_DONE="Super+d"
      SHORTCUT_EDIT="Super+e"
      SHORTCUT_SWITCH="Super+Tab"
      SHORTCUT_TERM="Super+t"
      SHORTCUT_FILTERS="Super+p"
      SHORTCUT_CLEAR="Super+c"
      SHORTCUT_HELP="Super+i" # not Super+h: i3 has Mod4+h/j/k/l
    '';

    # networkmanager_dmenu uses plain dmenu unless told to use rofi
    xdg.configFile."networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = rofi -dmenu -i
      compact = True
      wifi_chars = ▂▄▆█
    '';

    # The standalone helpers launch their own rofi window, so they can't be
    # modes of the main instance - surface them in drun (searchable from the
    # launcher) instead. networkmanager_dmenu already ships its own entry.
    xdg.desktopEntries = {
      rofi-bluetooth = {
        name = "Bluetooth";
        exec = "rofi-bluetooth";
        icon = "bluetooth";
      };
      rofi-screenshot = {
        name = "Screenshot / screen recording";
        exec = "rofi-screenshot";
        icon = "applets-screenshooter";
      };
      audio-output = {
        name = "Audio output";
        exec = "rofi-pulse-select sink";
        icon = "audio-speakers";
      };
      audio-input = {
        name = "Microphone select";
        exec = "rofi-pulse-select source";
        icon = "audio-input-microphone";
      };
      todo = {
        name = "Todo list";
        exec = "todofi.sh";
        icon = "org.gnome.Todo";
      };
      # `vpn-menu` comes from hosts/shared/global/nordvpn.nix, so the entry
      # only makes sense where that module is switched on.
      vpn = lib.mkIf osConfig.nordvpn.enable {
        name = "VPN (NordLynx)";
        exec = "vpn-menu";
        icon = "network-vpn";
      };
    };
  };
}
