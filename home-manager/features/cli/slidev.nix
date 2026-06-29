{pkgs, ...}: {
  # slidev-cli exists only in nixpkgs-unstable (not nixos-25.05), so it's
  # injected via the unstable overlay defined in flake.nix.
  home.packages = [pkgs.slidev-cli];
}
