{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.rofiModes;

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

  # Saved remmina profiles surfaced as a "remote" tab. rofi's own ssh mode is
  # built in and only reads ~/.ssh/config, so remote desktops get their own
  # mode instead. The profiles are read at runtime, so one added from the
  # remmina GUI shows up without a rebuild.
  rofi-remmina = pkgs.writeShellScriptBin "rofi-remmina" ''
    dir="''${XDG_DATA_HOME:-$HOME/.local/share}/remmina"

    if [ -z "$1" ]; then
      for f in "$dir"/*.remmina; do
        [ -e "$f" ] || continue
        name="" server="" user="" proto=""
        # key=value file; take the first hit for each key we display
        while IFS='=' read -r k v; do
          case "$k" in
          name) [ -n "$name" ] || name="$v" ;;
          server) [ -n "$server" ] || server="$v" ;;
          username) [ -n "$user" ] || user="$v" ;;
          protocol) [ -n "$proto" ] || proto="$v" ;;
          esac
        done <"$f"
        [ -n "$name" ] || name="''${f##*/}"
        # info\x1f<path> comes back as $ROFI_INFO on the selection call
        printf '%s\0icon\x1f%s\x1finfo\x1f%s\n' \
          "$name  ($proto $user@$server)" preferences-desktop-remote-desktop "$f"
      done
      exit 0
    fi

    [ -n "$ROFI_INFO" ] || exit 0
    setsid -f ${pkgs.remmina}/bin/remmina -c "$ROFI_INFO" >/dev/null 2>&1 </dev/null
  '';
in {
  options.rofiModes = {
    remote = lib.mkEnableOption "remmina remote-desktop tab in rofi";
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
      networkmanager_dmenu # wifi picker, launched from the polybar wlan icon
      papirus-icon-theme # icons for rofi drun mode
    ];

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
    };
  };
}
