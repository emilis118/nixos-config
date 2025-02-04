{ config, pkgs, inputs, ... }:

{
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;

    environment.systemPackages = with pkgs; [
        # kdePackages
    ];
}
