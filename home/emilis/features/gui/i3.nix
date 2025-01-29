# i3.nix

{ pkgs, lib, config, ... }: {

    home.file.".config/i3/config" = {
            source = "~/dotfiles/i3/config";
        };

    home.packages = with pkgs; [
        feh
            rofi
            rofi-calc
            nerd-fonts.jetbrains-mono
    ];
                            }
