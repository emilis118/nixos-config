{pkgs, ...}:
{
imports = [
    ./neovim.nix
    ./git.nix
];

home.packages = with pkgs; [
    alacritty
    git
    ripgrep
    fd

    nixd  # nix lsp
    alejandra  # formatter
    nh  # wrapper


    ];
}
