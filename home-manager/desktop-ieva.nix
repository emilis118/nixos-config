# Ieva's profile on `desktop`.
#
# Deliberately does not import ./global — that
# one hardcodes emilis' username, home directory and FLAKE path, and pulls in
# the rofi/dunst/polybar tooling that belongs to the i3 session.
#
# The desktop itself is Plasma 6 (hosts/shared/optional/kde.nix) and Steam is
# system-wide (optional/steam.nix), so only the per-user apps are here.
{pkgs, ...}: {
  programs.home-manager.enable = true;

  home.username = "ieva";
  home.homeDirectory = "/home/ieva";
  home.stateVersion = "26.05";

  imports = [
    ./features/minecraft.nix # prismlauncher
  ];

  home.packages = [pkgs.google-chrome];
}
