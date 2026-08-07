{...}: {
  programs.home-manager.enable = true;

  home.username = "emilis";
  home.homeDirectory = "/home/emilis";
  home.stateVersion = "25.05";

  imports = [
    ../features/cli
    ../features/firefox.nix
    ../features/rofi.nix
    ../features/dunst.nix
    ../features/passwords.nix
    ../features/dnd.nix
    ../features/cheatsheet
    ../features/clipboard.nix
    ../features/vlc.nix
  ];

  # sops-backed password store: `pw` in a terminal, or the "pw" tab in rofi.
  # Harmless before secrets/passwords.yaml exists — it just says so.
  passwordStore.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    # `pw` and `nh` both read this to find the repo
    FLAKE = "/home/emilis/00_projects/nixos-config";
  };
}
