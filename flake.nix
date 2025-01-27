{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
            home-manager.nixosModules.home-manager {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.users.emilis = import ./home/emilis/desktop.nix;
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
                home-manager.users.emilis = import ./home/emilis/laptop.nix;
                }
            ];
            specialArgs = {inherit inputs username;};
            };
        };

    # homeConfigurations = {
    #     # Main desktop
    #     "${username}@desktop" = home-manager.lib.homeManagerConfiguration {
    #         modules = [./home/${username}/desktop.nix ./home/${username}/nixpkgs.nix];        
    #         pkgs = nixpkgs.legacyPackages."x86_64-linux";
    #         extraSpecialArgs = {inherit inputs username;};
    #         };
    #
    #     # laptop
    #     "${username}@laptop" = home-manager.lib.homeManagerConfiguration {
    #         modules = [./home/${username}/laptop.nix ./home/${username}/nixpkgs.nix];        
    #         pkgs = nixpkgs.legacyPackages."x86_64-linux";
    #         extraSpecialArgs = {inherit inputs username;};
    #         };
    # };
  };
}
