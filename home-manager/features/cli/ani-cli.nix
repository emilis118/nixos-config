{pkgs, ...}: {
  # `ani-cli` here is pinned via the ani-cli-src flake input (offline fallback);
  # `ani` resolves GitHub HEAD on each launch (~1h cache) for provider fixes
  home.packages = with pkgs; [
    ani-cli
    ani-skip
    mov-cli
  ];

  programs.zsh.shellAliases.ani = "nix run github:pystardust/ani-cli --";
}
