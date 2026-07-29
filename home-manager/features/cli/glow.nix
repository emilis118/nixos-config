{pkgs, ...}: {
  # `glow file.md` renders markdown in the terminal; bare `glow` opens a
  # TUI browser over the markdown files under the current directory.
  home.packages = [pkgs.glow];
}
