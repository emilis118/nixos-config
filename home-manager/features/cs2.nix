{pkgs, ...}: {
  programs.gamemode.enable = true;
  home.packages = [pkgs.mangohud];
}
