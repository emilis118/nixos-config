{
  pkgs,
  lib,
  ...
}: let
  # TERM first; KILL if rofi is wedged too hard to act on it. Once rofi's X
  # connection is gone the server drops its keyboard/pointer grab by itself.
  rofiForceQuit = pkgs.writeShellScript "rofi-force-quit" ''
    ${pkgs.procps}/bin/pkill -x rofi || exit 0
    ${pkgs.coreutils}/bin/sleep 0.5
    ${pkgs.procps}/bin/pkill -KILL -x rofi
    exit 0
  '';

  # evdev keycodes (linux/input-event-codes.h)
  esc = 1;
  ctrls = [29 97]; # left, right
  alts = [56 100]; # left, right
in {
  # The i3 session itself is configured per-user in
  # home-manager/features/i3.nix; this is only the system side (session
  # registration + display manager).
  #
  # i3 comes with no file manager, so thunar rides along here — a Plasma host
  # (optional/kde.nix) has dolphin instead.
  imports = [./thunar.nix];

  # Ctrl+Alt+Esc force-quits rofi, the way out when it hangs.
  #
  # An i3 binding can't do this: an open rofi holds an active X keyboard
  # grab, so every key goes to rofi and i3 sees nothing, mod+Shift+q
  # included. actkbd reads the evdev devices directly, underneath X, so the
  # grab doesn't reach it. It doesn't grab the device itself either; X still
  # gets the keys, and with no rofi running the combo does nothing.
  #
  # Not in kde.nix: Plasma uses Ctrl+Alt+Esc for its own xkill.
  services.actkbd = {
    enable = true;
    bindings = lib.concatMap (ctrl:
      map (alt: {
        keys = [ctrl alt esc];
        events = ["key"];
        command = "${rofiForceQuit} &";
      })
      alts)
    ctrls;
  };

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

  environment.systemPackages = [pkgs.font-awesome];
}
