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
    ./../shared/optional/cern-lab.nix # /mnt/lab sshfs + davfs2
  ];

  # Networking
  networking.hostName = "pcte276928";

  # Enable OpenGL
  hardware.graphics.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
