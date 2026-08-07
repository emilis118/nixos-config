{
  pkgs,
  config,
  lib,
  ...
}: {
  # users.mutableUsers = false;
  users.users.emilis = {
    isNormalUser = true;
    shell = pkgs.zsh; # remember to have zsh
    initialPassword = "123456"; # set to proper secret
    home = "/home/emilis";
    extraGroups = [
      "wheel"
      "networkmanager"
      "gamemode"
      # /dev/kvm is root:kvm 0660, so running VMs unprivileged (quickemu,
      # qemu-system-*) needs this. Without it QEMU silently falls back to
      # software emulation, or refuses outright.
      "kvm"
    ];

    # packages = [pkgs.home-manager];
  };
}
