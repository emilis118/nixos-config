{pkgs, ...}: {
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    # `y` wraps yazi and cd's your shell into the last-visited dir on quit.
    # Pairs well with the tmux-sessionizer flow.
    shellWrapperName = "y";

    settings = {
      # NOTE: this table is named `manager` up to yazi 25.5.28 (current pin).
      # It was renamed to `mgr` in 25.5.31 — rename this key if you bump yazi.
      manager = {
        show_hidden = false;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
        ratio = [1 3 4];
      };
      preview = {
        max_width = 1000;
        max_height = 1000;
      };
    };
  };
}
