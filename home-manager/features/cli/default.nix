{pkgs, ...}:
{
imports = [
    ./neovim.nix
    ./git.nix
];

home.packages = with pkgs; [
    alacritty

    nixd  # nix lsp
    alejandra  # formatter
    nh  # wrapper
    ];
}
