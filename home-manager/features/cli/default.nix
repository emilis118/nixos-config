{pkgs, ...}: {
  imports = [
    ./neovim.nix
    ./git.nix
    ./alacritty.nix
    ./lf.nix
    ./tmux.nix
    ./zip.nix
    ./spreadsheet.nix
  ];

  home.packages = with pkgs; [
    nh # nix helper
  ];
}
