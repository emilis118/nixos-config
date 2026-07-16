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
    # ./../shared/optional/blocky.nix
    ./../shared/optional/performance.nix
    # ./../shared/optional/kde.nix  # temp kde while setting up
    ./../shared/optional/steam.nix
  ];

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.configurationLimit = 4;

  # Networking
  networking.hostName = "laptop";
  # trackpad
  services.libinput.enable = true;

  # Lid close suspends immediately, then hibernates to disk after 30 min so
  # a closed laptop doesn't drain the battery. Lid close while docked
  # (external monitor attached) is still ignored for clamshell use.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
  # hibernate image lives in the swap partition (hardware-configuration.nix)
  boot.resumeDevice = "/dev/disk/by-uuid/3ee88bae-d698-4c4c-830d-78c04bc11729";

  hardware.enableAllFirmware = true;

  services.xserver.videoDrivers = ["modesetting"]; # or "intel"
  services.tlp.enable = true;
  services.thermald.enable = true;

  # auto-apply saved xrandr profiles on monitor hotplug
  # (save one per docking spot with `autorandr --save <name>`)
  services.autorandr.enable = true;

  environment.systemPackages = with pkgs; [
    lm_sensors
    powertop
    intel-gpu-tools
    htop
  ];
  system.stateVersion = "24.11"; # Did you read the comment?
}
