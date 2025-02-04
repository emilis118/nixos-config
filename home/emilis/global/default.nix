{inputs, lib, pkgs, config, ...}:

{
    home.username = "emilis";
    home.homeDirectory = "/home/emilis";
    home.stateVersion = "24.11";

    imports = [
        ../features/cli
        ../features/gui/i3.nix
        ../features/firefox.nix
    ];

}
