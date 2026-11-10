{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
    # only used through its overlay, which builds against our pkgs anyway —
    # without this the lock carries a second, unused nixpkgs-unstable
    claude-code.inputs.nixpkgs.follows = "nixpkgs";
    # herdr: terminal multiplexer for AI agents; not in nixpkgs, so take the
    # upstream flake's overlay (exposes `herdr`, used in features/cli).
    herdr.url = "github:ogulcancelik/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs";
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    # age-encrypted secrets checked into this repo; see SOPS-SETUP.md
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Plasma settings (panels, theme, keyboard layouts) as home-manager
    # options; used only in Ieva's profile on `desktop`. No release branches,
    # trunk only, so it follows our nixpkgs and home-manager.
    plasma-manager.url = "github:nix-community/plasma-manager";
    plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
    plasma-manager.inputs.home-manager.follows = "home-manager";
    # last nixpkgs commit with prismlauncher 9.4 (the next one bumps it to
    # 10.0.0); used only for that package in features/minecraft.nix.
    nixpkgs-prism.url = "github:nixos/nixpkgs/c2fd2485d685ad6f4ed77b89991af722f282c5c7";
    # prebuilt nix-index database (updated weekly upstream), which is what
    # lets `, cmd` (comma) run a program that isn't installed without first
    # spending ten minutes indexing nixpkgs; used in features/cli/shell-tools.nix
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    claude-code,
    ...
  } @ inputs: let
    username = "emilis";
    system = "x86_64-linux";
    pkgsFor = nixpkgs.legacyPackages.${system};
    # allowUnfree and hostPlatform are set inside the host configs
    # (hosts/shared/global/base_config.nix and hardware-configuration.nix).
    overlaysModule = {
      nixpkgs.overlays = [
        claude-code.overlays.default
        inputs.herdr.overlays.default
      ];
    };
    # Every host is put together the same way: its own configuration.nix,
    # the overlays above, and home-manager wired to the matching profile in
    # ./home-manager. `name` picks both paths, so adding a host is one line
    # plus the two files.
    #
    # `extraHomeUsers` is for the machines that aren't only mine: each name in
    # it gets its own profile at ./home-manager/<host>-<user>.nix. The account
    # itself still has to exist (hosts/shared/users/<user>).
    mkHost = name: {extraHomeUsers ? []}:
      nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/${name}/configuration.nix
          overlaysModule
          inputs.sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = false;
            home-manager.extraSpecialArgs = {inherit inputs;};
            # Move a hand-written file aside instead of aborting the whole
            # activation when home-manager starts managing a path that
            # already exists (~/.ssh/config was the first such case).
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users =
              {${username} = import ./home-manager/${name}.nix;}
              // nixpkgs.lib.genAttrs extraHomeUsers
              (user: import ./home-manager/${name}-${user}.nix);
          }
        ];
        # hostName is the *flake* name (desktop, work_pc, ...), which is what
        # the per-host secrets files and .sops.yaml rules are keyed on;
        # networking.hostName is the machine's real name and differs at work.
        specialArgs = {
          inherit inputs username;
          hostName = name;
        };
      };

    hosts = {
      # Ieva's machine (Plasma, autologin); mine is only the admin account.
      # See hosts/desktop and hosts/shared/users/ieva.
      desktop = {extraHomeUsers = ["ieva"];};
      amd-desktop = {};
      laptop = {};
      work_pc = {};
      work_laptop = {};
      # shared lab machine: `cryolab` is the account the lab logs in with,
      # mine is only there to administer it, so it needs a second profile.
      daq-laptop = {extraHomeUsers = ["cryolab"];};
    };
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkHost hosts;

    # `nix fmt` formats the whole tree with the same formatter the neovim
    # setup uses for nix buffers. Wrapped because current Nix hands the
    # formatter no path when `nix fmt` is run bare, and alejandra with no
    # path sits reading stdin; this falls back to the current directory.
    # Arguments still pass through: `nix fmt -- --check .`
    formatter.${system} = pkgsFor.writeShellScriptBin "alejandra-tree" ''
      exec ${pkgsFor.alejandra}/bin/alejandra "''${@:-.}"
    '';

    # `nix flake check` evaluates every host on its own (it checks that each
    # nixosConfigurations.<name> toplevel is a derivation), which catches
    # option renames and typos without a rebuild. The hosts are deliberately
    # not listed under `checks` as well: checks get *built*, so that turned a
    # plain `nix flake check` into building all six system closures. The one
    # check here is cheap, so no --no-build is needed.
    checks.${system}.formatting =
      pkgsFor.runCommand "check-formatting" {
        nativeBuildInputs = [pkgsFor.alejandra];
      } ''
        alejandra --check ${./.}
        touch $out
      '';
  };
}
