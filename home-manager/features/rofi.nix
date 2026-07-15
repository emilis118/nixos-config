{pkgs, ...}: {
  programs.rofi = {
    enable = true;
    plugins = with pkgs; [
      rofi-calc # calculator
      rofi-top # load like htop
    ];
    extraConfig = {
      modi = "window,run,ssh,top,power:rofi-power-menu,bluetooth:rofi-bluetooth,ss:rofi-screenshot,audio:rofi-pulse-select";
    };
  };

  home.packages = with pkgs; [
    rofi-bluetooth
    rofi-screenshot
    rofi-power-menu
    rofi-pulse-select
    todofi-sh
    networkmanager_dmenu # wifi picker, launched from the polybar wlan icon
  ];

  # networkmanager_dmenu uses plain dmenu unless told to use rofi
  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    dmenu_command = rofi -dmenu -i
    compact = True
    wifi_chars = ▂▄▆█
  '';
}
