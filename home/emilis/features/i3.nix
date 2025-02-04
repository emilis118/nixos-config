# i3.nix

{ pkgs, lib, config, ... }: {

    home.file.".config/i3/config".source = builtins.path { path = "/home/emilis/dotfiles/i3/config"; };

    home.packages = with pkgs; [
            feh
            rofi
            rofi-calc
            (nerdfonts.override { fonts = ["JetBrainsMono"]; })
            # nerdfonts.jetbrains-mono
    ];
                            }
