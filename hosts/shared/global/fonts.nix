{pkgs, ...}:
{

	environment.systemPackages = with pkgs; [
            	(nerdfonts.override { fonts = ["JetBrainsMono"]; })
	];

}
