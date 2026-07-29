{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./neovim.nix
    ./git.nix
    ./alacritty.nix
    ./lf.nix
    ./yazi.nix
    ./tmux.nix
    ./zip.nix
    ./bat.nix
    ./glow.nix
    ./spreadsheet.nix
    ./slidev.nix
    ./claude.nix
  ];

  home.packages = with pkgs; [
    nh # nix helper
    herdr # agent multiplexer (tmux for AI agents)
  ];
}
