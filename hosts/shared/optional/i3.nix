{pkgs, ...}: {
  # The i3 session itself is configured per-user in
  # home-manager/features/i3.nix; this is only the system side (session
  # registration + display manager).
  #
  # i3 comes with no file manager, so thunar rides along here — a Plasma host
  # (optional/kde.nix) has dolphin instead.
  imports = [./thunar.nix];

  services.xserver.windowManager.i3.enable = true;
  services.displayManager.defaultSession = "none+i3";
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.autoNumlock = true;
  services.displayManager.sddm.settings = {
    Autologin = {
      Session = "none+i3";
      User = "emilis";
    };
    General = {
      Numlock = "on";
    };
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
