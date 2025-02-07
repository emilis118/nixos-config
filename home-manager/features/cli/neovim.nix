{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # Path to your custom Neovim configuration
    extraLuaConfig = ''
      source /etc/nixos/dotfiles/nvim/init.lua
    '';
  };

  # packages to have
  home.packages = with pkgs; [
    ripgrep
    fd
    gcc
  ];
}
