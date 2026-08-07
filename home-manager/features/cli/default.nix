{pkgs, ...}: {
  imports = [
    ./zsh.nix
    ./neovim.nix
    ./git.nix
    ./ssh.nix
    ./alacritty.nix
    ./lf.nix
    ./yazi.nix
    ./tmux.nix
    ./zip.nix
    ./bat.nix
    ./glow.nix
    ./mdb.nix
    ./spreadsheet.nix
    ./slidev.nix
    ./claude.nix
    ./mdb.nix
  ];

  home.packages = with pkgs; [
    nh # nix helper
    herdr # agent multiplexer (tmux for AI agents)
  ];
}
