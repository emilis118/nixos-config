{inputs, lib, pkgs, config, ...}:

{
    programs.home-manager.enable = true;

    home.username = "emilis";
    home.homeDirectory = "/home/emilis";
    home.stateVersion = "24.11";
    
    imports = [
        ../features/cli
        ../features/i3.nix
        ../features/firefox.nix
    ];

      home.sessionVariables = {
        EDITOR = "nvim";
      };

}
