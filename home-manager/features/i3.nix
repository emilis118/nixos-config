# i3.nix

{ pkgs, lib, config, ... }:

    let
        i3 = xsession.windowManager.i3;
    in {
    # ENABLE i3
    i3.enable = true;
    # remove later
    i3.extraConfig = "include $HOME/dotfiles/i3/config";

    # dependencies of i3 go here
    home.packages = with pkgs; [
            feh
            rofi
            rofi-calc
            (nerdfonts.override { fonts = ["JetBrainsMono"]; })
            # nerdfonts.jetbrains-mono
    ];

    # configuration
    

}
