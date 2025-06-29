{
  inputs,
  lib,
  pkgs,
  config,
  ...
}: {
  programs.home-manager.enable = true;

  home.username = "emilis";
  home.homeDirectory = "/home/emilis";
  home.stateVersion = "25.05";

  imports = [
    ../features/cli
    ../features/firefox.nix
    ../features/rofi.nix
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  nixpkgs.config.allowUnfree = true;
}
