{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
  let

    selectedSystem = "main-pc";
    # Define paths to the system configurations
    configPath = {
      main-pc = ./hosts/main-pc/configuration.nix;
      laptop = ./hosts/laptop/configuration.nix;
    };
    
  in {

    nixosConfigurations.${selectedSystem} = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        configPath.${selectedSystem}
	# check to see. 
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
