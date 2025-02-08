{inputs, lib, pkgs, config, ...}:

{
    programs.home-manager.enable = true;

    home.username = "emilis";
    home.homeDirectory = "/home/emilis";
    home.stateVersion = "24.11";
    
    imports = [
        ../features/cli
        ../features/firefox.nix
        ../features/rofi.nix
    ];

      home.sessionVariables = {
        EDITOR = "nvim";
      };

}
