{inputs, outputs, ...}:

{
    imports = [
        ./base_config.nix
        ./locale.nix
    	./fonts.nix
        ./zsh.nix
        ./../optional/i3.nix
        ./../users/emilis  # home-manager
    ];

}
