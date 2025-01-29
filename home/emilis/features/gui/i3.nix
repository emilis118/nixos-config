# i3.nix

{ pkgs, lib, config, ... }: {

    xsession.windowManager.i3 = {
        enable = true;
    };

    home.file.".config/i3" = {
        source = ~/dotfiles/i3;
        recursive = true;
        };


    home.packages = with pkgs; [
        feh
            rofi
            rofi-calc
    ];
                            }
