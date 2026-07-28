# My account on the DAQ laptop: admin only, almost always over ssh. So this
# is deliberately not ./global — that profile is the i3/X11 desktop (rofi,
# dunst, clipmenud, the password store), none of which means anything in a
# Plasma Wayland session I don't log into. Just the shell.
{
  programs.home-manager.enable = true;

  home.username = "emilis";
  home.homeDirectory = "/home/emilis";
  home.stateVersion = "26.05";

  imports = [
    ./features/cli
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    # `nh` reads this; clone the repo there if you want to rebuild from the
    # machine itself instead of `nixos-rebuild --target-host`
    FLAKE = "/home/emilis/00_projects/nixos-config";
  };
}
