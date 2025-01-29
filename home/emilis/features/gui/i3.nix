# i3.nix

{ pkgs, lib, config, ... }: {

    xsession.windowManager.i3 = {
        enable = true;
    };

    home.packages = with pkgs; [
        feh
            rofi
            rofi-calc
    ];
                            }
