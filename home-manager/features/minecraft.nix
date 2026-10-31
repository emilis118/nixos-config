{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    # pinned to 9.4 via the nixpkgs-prism flake input
    inputs.nixpkgs-prism.legacyPackages.${pkgs.stdenv.hostPlatform.system}.prismlauncher
  ];
}
