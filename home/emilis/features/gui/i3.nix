# i3.nix

{ pkgs, lib, config, ... }: {

    xsession.windowManager.i3 = {
        enable = true;
        configPath = /home/emilis/dotfiles/i3/config;
    };

    home.packages = with pkgs; [
        feh
            rofi
            rofi-calc
    ];
                            }
