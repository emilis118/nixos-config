# i3.nix

{ pkgs, lib, config, ... }: {

    # home.directory."$HOME/.config/i3".source = ./../i3;
    programs.i3.enable = true;
    programs.i3.extraConfig = "include $HOME/dotfiles/i3/config";

    home.packages = with pkgs; [
            feh
            rofi
            rofi-calc
            (nerdfonts.override { fonts = ["JetBrainsMono"]; })
            # nerdfonts.jetbrains-mono
    ];
                            }
