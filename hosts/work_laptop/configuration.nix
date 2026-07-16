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
  networking.hostName = "lapte277203";
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

  # Lid close suspends immediately, then hibernates to disk after 30 min so
  # a closed laptop doesn't drain the battery. Lid close while docked
  # (external monitor attached) is still ignored for clamshell use.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
  # hibernate image lives in the swap partition (hardware-configuration.nix)
  boot.resumeDevice = "/dev/disk/by-uuid/03305833-14ac-47ea-85c8-fd036c5b33a2";

  # Fingerprint reader (enroll with `fprintd-enroll`). This was previously
  # enabled in the laptop's pre-flake /etc/nixos config and silently dropped
  # on the first flake rebuild. Adds fingerprint to sudo/login PAM stacks.
  services.fprintd.enable = true;
  # ...but keep the lock screen password-only at the PAM level: fingerprint
  # unlock there is handled by the lock-screen watcher script (touch works
  # without pressing Enter first), and this keeps password+Enter instant
  # instead of waiting out a fingerprint timeout.
  security.pam.services.i3lock.fprintAuth = false;
  security.pam.services.i3lock-color.fprintAuth = false;

  hardware.enableAllFirmware = true;

  services.xserver.videoDrivers = ["modesetting"]; # or "intel"

  # auto-apply saved xrandr profiles on monitor hotplug
  # (save one per docking spot with `autorandr --save <name>`)
  services.autorandr.enable = true;

  # power management
  services.tlp.enable = true;
  services.thermald.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
