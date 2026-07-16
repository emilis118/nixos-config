{pkgs, ...}: {
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
      modi = "drun,run,window,ssh,calc,power:rofi-power-menu";
      show-icons = true;
      icon-theme = "Papirus-Dark";
      sidebar-mode = true; # clickable mode tabs at the bottom

      # Tab / Shift+Tab cycle modes instead of moving the selection
      kb-element-next = "";
      kb-element-prev = "";
      kb-mode-next = "Shift+Right,Control+Tab,Tab";
      kb-mode-previous = "Shift+Left,Control+ISO_Left_Tab,ISO_Left_Tab";

      display-drun = "apps";
      display-run = "run";
      display-window = "windows";
      display-ssh = "ssh";
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
}
