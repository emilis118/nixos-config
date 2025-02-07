# i3.nix

{ pkgs, lib, config, ... }:

    {

    # dependencies of i3 go here
    home.packages = with pkgs; [
	    i3lock
	    i3status
	    i3blocks
            feh
            rofi
            rofi-calc
    ];


}
