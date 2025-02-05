{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
    let
        username = "emilis";
    in
    {
    nixosConfigurations = {
        # Main desktop
        desktop = nixpkgs.lib.nixosSystem {
            modules = [
            ./hosts/desktop/configuration.nix
            ];
            specialArgs = {inherit inputs username;};
            };

        # laptop
        laptop = nixpkgs.lib.nixosSystem {
            modules = [
            ./hosts/laptop/configuration.nix
            ];
            specialArgs = {inherit inputs username;};
            };
        };
  };
}
