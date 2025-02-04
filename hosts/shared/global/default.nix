{inputs, outputs, ...}:

{
    imports = [
        ./base_config.nix
        ./locale.nix
        ./i3.nix
        ./../users/emilis  # home-manager
    ];

}
