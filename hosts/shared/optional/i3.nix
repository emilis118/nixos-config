{pkgs, ...}: {
  services.xserver.windowManager.i3.enable = true;
  services.displayManager.defaultSession = "none+i3";
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.settings = {
    Autologin = {
      Session = "none+i3";
      User = "emilis";
    };
    General = {
      Numlock = "on";
    };
  };

  services.xserver.windowManager.i3 = {
    configFile = ./../../../dotfiles/i3/config;
    extraPackages = with pkgs; [
      i3status
      i3blocks
      i3lock
      feh
      (polybar.override {
        i3Support = true;
        pulseSupport = true; # if needed for volume
      })
    ];
  };

  environment.systemPackages = [
    (pkgs.writeShellScriptBin
      "start-discord"
      ''
        #!/bin/bash

        # Check if Discord is running, start it if not
        pgrep Discord || (discord &)

        # Switch to the specified workspace
        i3-msg workspace "9:Discord"

      '')
    pkgs.font-awesome
  ];
}
