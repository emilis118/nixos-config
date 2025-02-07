# firefox.nix

{ pkgs, lib, config, ... }: {

    home.packages = with pkgs; [
        firefox
    ];
                            }

