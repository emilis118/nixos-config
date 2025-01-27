{pkgs, ...}:
{
imports = [

];

home.packages = with pkgs; [
    alacritty
    neovim
    git
    ripgrep
    fd

    nixd  # nix lsp
    alejandra  # formatter
    nh  # wrapper


    ];
}
