{ pkgs, ... }:

    let
    rofiPowerMenu = "${pkgs.rofi-power-menu}/bin/rofi-power-menu";
    in {
    programs.rofi = {
        enable = true;
        plugins = with pkgs; [
            rofi-calc  # calculator
            rofi-bluetooth  # bluetooth manager
            rofi-top  # load like htop
            rofi-screenshot  # screenshot and screenrecord
            rofi-power-menu  # power menu
            rofi-pulse-select  # select audio output
            todofi-sh  # todo list
        ];
        extraConfig = {
            modi = "window,run,ssh,top,power";
            };
        };

    home.file.".config/rofi/scripts/rofi-power-menu.sh".text = ''
        #!/bin/sh
        ${rofiPowerMenu}
    '';

    home.packages = [ pkgs.rofi-power-menu ];

    home.sessionVariables.ROFI_POWER_MENU = rofiPowerMenu;

}
