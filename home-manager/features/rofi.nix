{ pkgs, ... }: {

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
        };
}
