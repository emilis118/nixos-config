# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../shared/global # auto picks default.nix
    ./../shared/optional/blocky.nix
    # ./../shared/optional/kde.nix  # temp kde while setting up
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.configurationLimit = 4;

  # Networking
  networking.hostName = "laptop";
  # trackpad
  services.libinput.enable = true;

  services.logind = {
    enable = true;
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
  };
}
