{inputs, outputs, ...}:

{
    imports = [
        ./base_config.nix
        ./../users/emilis
        ./locale.nix
    ];

    programs.zsh.enable = true;
}
