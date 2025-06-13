{pkgs, ...}: {
  fonts.packages = with pkgs; [
    # (nerdfonts.override {fonts = ["JetBrainsMono"];})
    # from 25.05 nixpkgs
    nerd-fonts.jetbrains-mono
  ];
}
