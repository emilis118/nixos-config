# Throwaway config for bringing the AMD box up the first time. Boots, gets on
# the network, gives you a shell — nothing else. The point is a rebuild that
# finishes in minutes on a fresh install, from which you can then run
#
#   sudo nixos-rebuild switch --flake .#amd-desktop
#
# and let the real config download at its leisure. Delete this host once that
# has worked.
#
# No X, no display manager, no home-manager features: you land on a tty.
{
  lib,
  pkgs,
  ...
}: {
  imports = [
    # Deliberately the *same* file amd-desktop uses, not a copy — the disk
    # UUIDs in it are placeholders until the real hardware scan is pasted in,
    # and doing that twice is how the two configs drift apart. It also brings
    # the AMD microcode and kvm-amd along.
    ./../amd-desktop/hardware-configuration.nix
    # Just these three of shared/global — not the directory, because its
    # default.nix also pulls in X11, pipewire, printing, bluetooth and fonts.
    ./../shared/global/boot.nix # systemd-boot, UEFI
    ./../shared/global/nix.nix # flakes; without this the rebuild can't run
    ./../shared/global/locale.nix # timezone, locales
    ./../shared/users/emilis # the account itself
  ];

  networking.hostName = "amd-bootstrap";

  # Something has to get this machine online or it can't fetch the real
  # config. Wired DHCP would already work via networking.useDHCP in the
  # hardware scan; NetworkManager is here so wifi is an option too (`nmtui`),
  # and emilis is already in its group.
  networking.networkmanager.enable = true;

  # The isolated core, from the start — this is the one piece of the real
  # config worth having here, since it is a boot-time setting and this is the
  # config that does the booting. Kept byte-identical to amd-desktop's; see
  # that file for why both threads of the core are named.
  boot.kernelParams = [
    "isolcpus=10,22"
    "nohz_full=10,22"
    "rcu_nocbs=10,22"
    "irqaffinity=0-9,11-21,23"
  ];

  # shared/users/emilis sets zsh as the login shell, which needs
  # programs.zsh.enable and the whole shell config to be worth having. On a
  # tty-only bootstrap bash is the shorter path.
  users.users.emilis.shell = lib.mkForce pkgs.bashInteractive;

  # The account's initialPassword is in shared/users/emilis (123456) — it only
  # applies on first activation, which is exactly this one.

  # Enough to clone the repo and edit a file, and nothing beyond it.
  environment.systemPackages = with pkgs; [git vim];

  # base_config.nix isn't imported here, so this has to be repeated: the
  # redistributable CPU microcode/firmware the hardware scan enables is unfree.
  nixpkgs.config.allowUnfree = true;

  # Matches amd-desktop rather than being "correct" for a fresh install, so
  # that switching between the two configs doesn't move any state-version
  # dependent defaults underneath you.
  system.stateVersion = "24.11";
}
