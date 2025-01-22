# i3.nix

{ pkgs, lib, config, ... }: {

  options = {
    i3.enable = lib.mkEnableOption "enables i3";
  };

  config = lib.mkIf config.i3.enable {
    services.xserver.windowManager.i3.enable = true;
    services.xserver.windowManager.i3.configFile = "~/dotfiles/i3/config";
    };
}
