{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
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
    # allowUnfree and hostPlatform are set inside the host configs
    # (hosts/shared/global/base_config.nix and hardware-configuration.nix).
    overlaysModule = {
      nixpkgs.overlays = [
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
          overlaysModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/desktop.nix;
          }
        ];
        specialArgs = {inherit inputs username claude-code;};
      };

      # laptop
      laptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/laptop/configuration.nix
          overlaysModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/laptop.nix;
          }
        ];
        specialArgs = {inherit inputs username claude-code;};
      };

      work_pc = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/work_pc/configuration.nix
          overlaysModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/work_pc.nix;
          }
        ];
        specialArgs = {inherit inputs username claude-code;};
      };

      work_laptop = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/work_laptop/configuration.nix
          overlaysModule
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.users."emilis" = import ./home-manager/work_laptop.nix;
          }
        ];
        specialArgs = {inherit inputs username claude-code;};
      };
    };
  };
}
