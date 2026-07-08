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
      options = "nodev,noatime,allow_other,reconnect,ServerAliveInterval=15,ConnectTimeout=5,IdentityFile=/home/emilis/.ssh/lab_pc";
      after = ["network-online.target"];
      wants = ["network-online.target"];
      # No wantedBy here: only the automount unit is started at boot, so the
      # sshfs connection is attempted on first access instead of blocking boot.
      mountConfig.TimeoutSec = 15;
    }
  ];

  systemd.automounts = [
    {
      where = "/mnt/lab";
      wantedBy = ["multi-user.target"];
    }
  ];

  programs.fuse.userAllowOther = true;
  environment.systemPackages = [pkgs.sshfs];

  services.davfs2.enable = true;
  # fileSystems."/mnt/dfs" = {
  #   device = "https://dfs.cern.ch/dfs";
  #   fsType = "davfs";
  #   options = ["rw" "noauto" "_netdev"];
  # };
  #
  # systemd.mounts = [
  #   {
  #     what = "https://dfs.cern.ch/dfs";
  #     where = "/mnt/dfs";
  #     type = "davfs";
  #     options = "rw";
  #     wants = ["network-online.target"];
  #     after = ["network-online.target"];
  #   }
  # ];

  # bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Networking
  networking.hostName = "pcte276928";

  # Enable OpenGL
  hardware.graphics.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.configurationLimit = 4;

  # wireless "error"
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
