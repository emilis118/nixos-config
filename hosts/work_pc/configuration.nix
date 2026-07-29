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
    ./../shared/optional/cern-lab.nix # /mnt/lab sshfs + davfs2
  ];

  # Networking
  networking.hostName = "pcte276928";

  # sops-nix. Installs every key in secrets/common.yaml (the `secrets.sshKeys`
  # default), which includes the `lab_pc` one cern-lab.nix's /mnt/lab sshfs
  # mount points at.
  secrets.enable = true;

  # NordLynx, available but never automatic: this is a full tunnel, so while
  # it is up the /mnt/lab sshfs mount and anything else CERN-internal stops
  # resolving. Bring it up deliberately with `vpn up`, and `vpn down` before
  # touching the lab.
  nordvpn.enable = true;

  # Enable OpenGL
  hardware.graphics.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
