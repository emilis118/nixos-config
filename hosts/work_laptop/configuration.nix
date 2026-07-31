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
    ./../shared/optional/i3.nix # sddm + i3 session
    # lid/hibernate handling, tlp + thermald, autorandr, laptop diagnostics
    # tooling; also pulls in optional/performance.nix
    ./../shared/optional/laptop.nix
    ./../shared/optional/cern-lab.nix # /mnt/lab sshfs + davfs2
  ];

  # Networking
  networking.hostName = "lapte277203";

  # Enable OpenGL
  hardware.graphics.enable = true;

  # hibernate image lives in the swap partition (hardware-configuration.nix)
  boot.resumeDevice = "/dev/disk/by-uuid/03305833-14ac-47ea-85c8-fd036c5b33a2";

  # sops-nix. Installs every key in secrets/common.yaml (the `secrets.sshKeys`
  # default), which includes the `lab_pc` one cern-lab.nix's /mnt/lab sshfs
  # mount points at.
  secrets.enable = true;

  # NordLynx, available but never automatic: this is a full tunnel, so while
  # it is up the /mnt/lab sshfs mount and anything else CERN-internal stops
  # resolving. Bring it up deliberately with `vpn up`, and `vpn down` before
  # touching the lab.
  nordvpn.enable = true;

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

  # Not worth putting the enrollment under sops: /var/lib/fprint holds only a
  # binding to a print ID stored on the sensor chip, keyed by that chip's USB
  # serial, so a backup restores nothing except on this exact laptop with
  # this exact sensor - and goes stale the moment you re-enroll.

  system.stateVersion = "25.05"; # Did you read the comment?
}
