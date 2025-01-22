{ config, pkgs, ... }:

{
# List packages installed in system profile. To search, run:
# $ nix search wget
    environment.systemPackages = with pkgs; [
        # A
        alacritty
        # G
        git
        # I
        i3
        # L
        lf
        # N
        neovim
    ];
}
