{inputs, outputs, ...}:

{
    imports = [
        ./base_config.nix
        ./locale.nix
	./fonts.nix
        ./../optional/i3.nix
        ./../users/emilis  # home-manager
    ];

}
