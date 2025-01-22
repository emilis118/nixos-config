{pkgs, ...}:
{
imports = [

];

home.packages = with pkgs; [
    alacritty
    ripgrep
    fd

    nixd  # nix lsp
    alejandra  # formatter
    nh  # wrapper


    ];
}
