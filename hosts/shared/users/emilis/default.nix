{
  pkgs,
  config,
  lib,
  ...
}:
{
  users.mutableUsers = false;
  users.users.emilis = {
    isNormalUser = true;
    shell = pkgs.zsh;
    initialPassword = "123456";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];

    packages = [pkgs.home-manager];
  };

  # home-manager.users.gabriel = import ../../../../home/gabriel/${config.networking.hostName}.nix;

}
