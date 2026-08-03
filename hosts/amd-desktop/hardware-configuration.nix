# Placeholder hardware scan — NOT generated on the real machine yet.
#
# Everything below except the CPU/microcode lines is a guess copied from
# `desktop`. Before the first `nixos-rebuild switch` on this box, run
#
#   sudo nixos-generate-config --show-hardware-config
#
# on it and paste the fileSystems / swapDevices / initrd module lists over
# the ones here (keep the AMD bits at the bottom). The device UUIDs are
# deliberately invalid so a mistake fails at mount time instead of silently
# mounting the wrong disk.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  # AMD host, so the KVM module is kvm-amd (the Intel machines load kvm-intel).
  boot.kernelModules = ["kvm-amd"];
  boot.extraModulePackages = [];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ROOT-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ESP-UUID";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/REPLACE-WITH-SWAP-UUID";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Ryzen 9 3900X (Zen 2). AMD microcode, not Intel — this is what ships the
  # AGESA/ucode updates the kernel loads early at boot; it needs unfree
  # redistributable firmware, which base_config already allows.
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;
}
