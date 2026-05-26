#  firefox.nix
{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.firefox.enable = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = ["firefox.desktop"];
    };
  };
  # home.packages = with pkgs; [
  #     firefox
  # ];
}
