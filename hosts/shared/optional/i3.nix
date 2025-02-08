{ pkgs, ... }:
{
    services.xserver.windowManager.i3.enable = true;
    services.xserver.displayManager.defaultSession = "none+i3";
    services.xserver.displayManager.sddm.enable = true;
    
    services.xserver.windowManager.i3 = {
    	configFile = ./../../../dotfiles/i3/config;
	extraPackages = with pkgs; [
		i3status
		i3blocks
		i3lock
        feh
	];
	};
    
}
