# PLACEHOLDER — this machine hasn't been installed yet, so nothing here came
# from a hardware scan. It is only enough for the config to evaluate and
# build. On the real machine, replace this whole file with
#
#   nixos-generate-config --show-hardware-config
#
# before the first switch, or it will boot into a shell with no root
# filesystem. The disk labels below are what the NixOS installation manual's
# partitioning commands produce (`mkfs.ext4 -L nixos`, `mkfs.fat -n boot`);
# if you follow it exactly they happen to be right, but check anyway.
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  # No swap declared: this host never hibernates (see configuration.nix).
  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
