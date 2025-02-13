{pkgs, ...}: {
  imports = [
    ./neovim.nix
    ./git.nix
    ./alacritty.nix
    ./lf.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    nh # nix helper
  ];
}
