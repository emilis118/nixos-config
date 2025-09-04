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
    ];

    # packages = [pkgs.home-manager];
  };
}
