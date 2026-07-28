# The lab's account. Plasma provides the desktop, so this is the terminal
# side of it (same shell, editor and tooling as everywhere else) plus the
# office suite.
{lib, ...}: {
  programs.home-manager.enable = true;

  home.username = "cryolab";
  home.homeDirectory = "/home/cryolab";
  home.stateVersion = "26.05";

  imports = [
    ./features/cli
    ./features/onlyoffice.nix
  ];

  # features/cli/git.nix commits as me, which on an account several people
  # share would put my name on the lab's work. ~/.config/git/config is a
  # read-only store symlink, so anyone who needs their own identity sets it
  # per repository (`git config user.name ...`).
  programs.git.settings.user = {
    name = lib.mkForce "cryolab";
    email = lib.mkForce "cryolab@lapte234119";
  };

  home.sessionVariables.EDITOR = "nvim";
}
