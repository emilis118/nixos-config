{ pkgs, ... }:

{
    programs.rofi = {
        enable = true;
        plugins = with pkgs; [
            rofi-calc  # calculator
            rofi-top  # load like htop
        ];
        extraConfig = {
            modi = "window,run,ssh,top,power,bluetooth:rofi-bluetooth,ss:rofi-screenshot,audio:rofi-pulse-select";
            };
        };

    home.packages = with pkgs; [ 
    rofi-bluetooth
    rofi-screenshot
    rofi-power-menu 
    rofi-pulse-select
    todofi-sh
    ];

}
