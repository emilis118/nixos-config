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
    # lid/hibernate handling, tlp + thermald, autorandr, laptop diagnostics
    # tooling; also pulls in optional/performance.nix
    ./../shared/optional/laptop.nix
    ./../shared/optional/steam.nix
  ];

  # Networking
  networking.hostName = "laptop";

  # hibernate image lives in the swap partition (hardware-configuration.nix)
  boot.resumeDevice = "/dev/disk/by-uuid/3ee88bae-d698-4c4c-830d-78c04bc11729";

  system.stateVersion = "24.11"; # Did you read the comment?
}
