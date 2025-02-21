let
myPkgs = import <nixpkgs>;
in
{
  services.xserver.windowManager.i3.enable = true;
  services.xserver.displayManager.defaultSession = "none+i3";
  services.xserver.displayManager.sddm.enable = true;

  services.xserver.windowManager.i3 = {
    configFile = ./../../../dotfiles/i3/config;
    extraPackages = with myPkgs; [
      i3status
      i3blocks
      i3lock
      feh
    ];
  };

  users.users.emilis.packages = [
    myPkgs.writeShellScriptBin
    "start-discord"
    ''
      #!/bin/bash

      # Check if Discord is running, start it if not
      pgrep Discord || (discord &)

      # Switch to the specified workspace
      i3-msg workspace "9:Discord"

    ''
  ];
}
