{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    username = "emilis";
    system = "x86_64-linux";
    pkgs = import nixpkgs {
        legacyPackages.${system};
        config.allowUnfree = true;
        };
  in {
    nixosConfigurations = {
      # Main desktop
      desktop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."emilis" = import ./home-manager/desktop.nix;
            nixpkgs.config.allowUnfree = true;
          }
        ];
        specialArgs = {inherit pkgs inputs username;};
      };

      # laptop
      laptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/laptop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users."emilis" = import ./home-manager/laptop.nix;
            nixpkgs.config.allowUnfree = true;
          }
        ];
        specialArgs = {inherit pkgs inputs username;};
      };
    };
  };
}
