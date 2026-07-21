{pkgs, ...}: {
  home.packages = [pkgs.remmina];

  # saved remmina profiles get their own tab in rofi (see rofi.nix)
  rofiModes.remote = true;
}
