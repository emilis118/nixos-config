{
  # Every host boots UEFI + systemd-boot; nothing here uses GRUB.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Cap the boot menu (and therefore the kernels/initrds copied to the ESP).
  # This has to be the systemd-boot option — boot.loader.grub.configurationLimit
  # is silently ignored when GRUB is disabled, which lets the ESP fill up until
  # a rebuild fails with "No space left on device".
  boot.loader.systemd-boot.configurationLimit = 4;
}
