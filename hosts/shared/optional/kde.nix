{pkgs, ...}: {
  # Plasma 6 on Wayland, the alternative to optional/i3.nix. A host imports
  # one or the other, never both: they both set
  # services.displayManager.defaultSession.
  #
  # Almost everything comes from the plasma6 module's own defaults — it
  # already turns on sddm, sddm.wayland (kwin as the greeter compositor) and
  # sets defaultSession = "plasma", the Wayland session. That default is worth
  # keeping rather than switching to "plasmax11": KRDP, Plasma's built-in RDP
  # server (optional/remote-access.nix), only works in a Wayland session.
  # X11 programs still run under XWayland.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.autoNumlock = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kate # the editor Plasma's "open in text editor" expects
    kdePackages.filelight # what is eating the disk
  ];
}
