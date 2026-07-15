#  firefox.nix
{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.firefox.enable = true;
  # keep the pre-26.05 profile location; existing profiles live in ~/.mozilla
  programs.firefox.configPath = ".mozilla/firefox";

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
