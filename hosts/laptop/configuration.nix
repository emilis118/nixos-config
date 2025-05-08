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
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
  };

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  services.xserver.videoDrivers = ["intel"]; # or "intel"
  services.tlp.enable = true;
  services.thermald.enable = true;

  environment.systemPackages = with pkgs; [
    lm_sensors
    powertop
    intel-gpu-tools
  ];
}
