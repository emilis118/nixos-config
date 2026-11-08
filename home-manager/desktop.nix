# My account on `desktop`, which is Ieva's machine now: admin only (sudo,
# rebuilds), so the same shell-only profile as daq-laptop.nix rather than
# roles/personal. The i3/rofi/polybar/dunst tooling has no session to run in
# here, and dunst would fight Plasma over the notification bus.
{
  programs.home-manager.enable = true;

  home.username = "emilis";
  home.homeDirectory = "/home/emilis";
  home.stateVersion = "25.05";

  imports = [
    ./features/cli
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    # `nh` reads this to find the repo
    FLAKE = "/home/emilis/00_projects/nixos-config";
  };
}
