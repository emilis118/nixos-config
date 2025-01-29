{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    # Path to your custom Neovim configuration
    extraConfig = ''
      source ~/.config/nvim/init.lua
    '';
  };
}
