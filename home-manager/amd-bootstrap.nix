# Bootstrap profile: flake.nix wires a home-manager profile into every host,
# so this file has to exist — but the whole point of amd-bootstrap is to not
# build any of ./global's tooling, so it stays empty apart from the identity
# home-manager needs.
{
  programs.home-manager.enable = true;

  home.username = "emilis";
  home.homeDirectory = "/home/emilis";
  home.stateVersion = "25.05";
}
