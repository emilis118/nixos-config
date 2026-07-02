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
    ./../shared/optional/performance.nix
  ];

  programs.ssh.knownHosts = {
    "pxicryolab05.cern.ch" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPNZ9R7xssGHbricQ5fUc3S0IkebV55tSrP+b8ZwOTWz";
    };
  };

  systemd.mounts = [
    {
      what = "cryolab@pxicryolab05.cern.ch:/home/cryolab";
      where = "/mnt/lab";
      type = "fuse.sshfs";
      options = "nodev,noatime,allow_other,IdentityFile=/home/emilis/.ssh/lab_pc";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];
    }
  ];

  systemd.automounts = [
    {
      where = "/mnt/lab";
      wantedBy = ["multi-user.target"];
    }
  ];

  programs.fuse.userAllowOther = true;
  environment.systemPackages = with pkgs; [
    sshfs
    # laptop diagnostics / power tooling
    lm_sensors
    powertop
    intel-gpu-tools
    htop
  ];

  services.davfs2.enable = true;

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Networking
  networking.hostName = "work-laptop";
  networking.networkmanager.enable = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.configurationLimit = 4;

  # --- Laptop-specific bits ---
  # trackpad
  services.libinput.enable = true;

  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "suspend";
  };

  hardware.enableAllFirmware = true;

  services.xserver.videoDrivers = ["modesetting"]; # or "intel"

  # power management
  services.tlp.enable = true;
  services.thermald.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
