{pkgs, ...}:
{
imports = [
    ./neovim.nix
    ./git.nix
];

home.packages = with pkgs; [
    alacritty

    nh # nix helper
    ];
}
