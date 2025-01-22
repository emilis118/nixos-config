{ lib, config, pkgs, ... }:

let
  cfg = config.main-user;
in
{
  options.main-user = {
    enable = lib.mkEnableOption "enable user module";

    userName = lib.mkOption {
      default = "emilis";
      description = ''username'';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      initialPassword = "123456";
      description = "main user";
      extraGroups = [ "NetworkManager" "wheel" ];
      shell = pkgs.zsh;
    };
  };
}
