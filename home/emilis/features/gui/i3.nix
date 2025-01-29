# i3.nix

{ pkgs, lib, config, ... }: {

    programs.xserver.enable = true;
    services.xserver.windowManager.i3.enable = true;
    services.xserver.windowManager.i3.configFile = "~/dotfiles/i3/config";

    home.packages = with pkgs; [
        feh
        rofi
        rofi-calc
        ];
}
