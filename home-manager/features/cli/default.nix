{pkgs, ...}: {
  imports = [
    ./neovim.nix
    ./git.nix
    ./alacritty.nix
    ./lf.nix
    ./yazi.nix
    ./tmux.nix
    ./zip.nix
    ./spreadsheet.nix
    ./slidev.nix
    ./claude.nix
  ];

  home.packages = with pkgs; [
    nh # nix helper
  ];
}
