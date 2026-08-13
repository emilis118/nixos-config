{
  description = "NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    claude-code.url = "github:sadjow/claude-code-nix";
    # herdr: terminal multiplexer for AI agents; not in nixpkgs, so take the
    # upstream flake's overlay (exposes `herdr`, used in features/cli).
    herdr.url = "github:ogulcancelik/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs";
    # nixy's neovim (built with nvf); flake = false so we don't pull in
    # nixy's heavy inputs (hyprland, stylix, ...) — we only use its nvf modules.
    nvf.url = "github:notashelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";
    nixy.url = "github:anotherhadi/nixy";
    nixy.flake = false;
    nixvim.url = "github:nix-community/nixvim/nixos-26.05";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    # age-encrypted secrets checked into this repo; see SOPS-SETUP.md
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
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
        # nixy's neovim as a separate package, exposed as `nnvim` in neovim.nix
        (final: _prev: {
          nixy-nvim =
            (inputs.nvf.lib.neovimConfiguration {
              pkgs = final;
              modules =
                map (m: "${inputs.nixy}/home/programs/nvf/${m}.nix") [
                  "options"
                  "languages"
                  "picker"
                  "snacks"
                  "keymaps"
                  "utils"
                  "mini"
                ]
                ++ [./home-manager/features/cli/nnvim-overrides.nix];
            })
            .neovim;
        })
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
      # ieva has her own account on this one (Plasma, autologin); see
      # hosts/shared/users/ieva.
      desktop = {extraHomeUsers = ["ieva"];};
      # TEMP-IEVA: revert to `amd-desktop = {};` when she stops using it.
      amd-desktop = {extraHomeUsers = ["ieva"];};
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
    # setup uses for nix buffers.
    formatter.${system} = pkgsFor.alejandra;

    # `nix flake check` evaluates every host and verifies formatting, which
    # catches option renames and typos without a rebuild.
    checks.${system} =
      nixpkgs.lib.mapAttrs
      (name: _: self.nixosConfigurations.${name}.config.system.build.toplevel)
      hosts
      // {
        formatting =
          pkgsFor.runCommand "check-formatting" {
            nativeBuildInputs = [pkgsFor.alejandra];
          } ''
            alejandra --check ${./.}
            touch $out
          '';
      };
  };
}
