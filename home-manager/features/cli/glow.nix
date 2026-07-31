{pkgs, ...}: {
  # `glow file.md` renders markdown in the terminal; bare `glow` opens a
  # TUI browser over the markdown files under the current directory.
  home.packages = [pkgs.glow];

  # `md file.md` — rendered markdown through a pager; bare `md` opens the TUI.
  programs.zsh.shellAliases.md = "glow -p";
}
