# i3.nix

{ pkgs, lib, config, ... }: {

    home.packages = with pkgs; [
        feh
        rofi
        rofi-calc
        ];
}
