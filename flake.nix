{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: 
    let
        username = "emilis";
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        home = home-manager.lib.homeManagerConfiguration;
    in
    {
    nixosConfigurations = {
        # Main desktop
        desktop = nixpkgs.lib.nixosSystem {
            modules = [
            ./hosts/desktop/configuration.nix
            home-manager.nixosModules.home-manager {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.emilis = import ./home-manager/desktop.nix;
                }
            ];
            specialArgs = {inherit inputs username;};
            };

        # laptop
        laptop = nixpkgs.lib.nixosSystem {
            modules = [
            ./hosts/laptop/configuration.nix
            home-manager.nixosModules.home-manager {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.emilis = import ./home-manager/laptop.nix;
                }
            ];
            specialArgs = {inherit inputs username;};
            };
        };

    # homeConfigurations = {
    #     "${username}@desktop" = home {
    #         inherit pkgs;
    #         configuration = ./home-manager/desktop.nix;
    #         };
    #
    #
    #     "${username}@laptop" = home {
    #         inherit pkgs;
    #         configuration = ./home-manager/laptop.nix;
    #         };
    #
    #     };
  };
}
