{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    claude-code,
    ...
  } @ inputs: let
    username = "emilis";
    system = "x86_64-linux";
    # pkgs = nixpkgs.legacyPackages.${system};
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        claude-code.overlays.default
        # slidev-cli isn't in nixos-25.05; pull just that package from unstable.
        (final: _prev: {
          slidev-cli =
            (import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            })
            .slidev-cli;
        })
      ];
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
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/desktop.nix;
          }
        ];
        specialArgs = {inherit pkgs inputs username claude-code;};
      };

      # laptop
      laptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/laptop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/laptop.nix;
          }
        ];
        specialArgs = {inherit pkgs inputs username claude-code;};
      };

      work_pc = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/work_pc/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/work_pc.nix;
          }
        ];
        specialArgs = {inherit pkgs inputs username claude-code;};
      };
    };
  };
}
