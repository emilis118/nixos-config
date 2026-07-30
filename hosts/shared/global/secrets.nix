{
  config,
  lib,
  pkgs,
  hostName,
  ...
}:
with lib; let
  cfg = config.secrets;
in {
  # sops-nix: secrets live encrypted in ./secrets/*.yaml in this repo and are
  # decrypted into /run/secrets at activation time. Recipients are declared in
  # ../../../.sops.yaml — one admin key (yours) plus one key per machine.
  #
  # Inert until a host sets `secrets.enable = true`, because turning it on
  # before the host's age key exists makes activation fail. Follow
  # SOPS-SETUP.md once, then flip it.
  options.secrets = {
    enable = mkEnableOption "sops-nix secret decryption on this host";

    ageKeyFile = mkOption {
      type = types.str;
      default = "/var/lib/sops-nix/key.txt";
      description = ''
        This machine's private age key — its "slot" in .sops.yaml. Not in the
        repo and never leaves the machine; only the public half goes into
        .sops.yaml. Create it with SOPS-SETUP.md step 2.
      '';
    };

    sshKeys = mkOption {
      type = types.listOf types.str;
      default = ["lab_pc" "gitlab" "github"];
      example = ["lab_pc"];
      description = ''
        Names of ssh private keys to install into ~/.ssh. Each one must exist
        as an `ssh/<name>` entry in secrets/common.yaml. The public half is
        not managed here.

        Defaults to every key in that file: the machines are all mine, and a
        key that only lives on one of them is a key I can't use from the
        others. Override with a shorter list (or `[]`) on a host that
        shouldn't hold all of them.

        home-manager/features/cli/ssh.nix reads this list back out to decide
        which ~/.ssh/config blocks to write, so a key added here starts being
        offered to the right host without a second edit.
      '';
    };
  };

  config = mkIf cfg.enable {
    sops = {
      # Everything the machines need. Encrypted to the admin key + every host
      # key, so any machine can decrypt it.
      defaultSopsFile = ../../../secrets/common.yaml;
      defaultSopsFormat = "yaml";

      age = {
        keyFile = cfg.ageKeyFile;
        # Create the key on first activation if it is missing. Doing it by
        # hand first (SOPS-SETUP.md step 2) is better: a generated key is not
        # yet a recipient of anything, so that activation still fails.
        generateKey = true;
        # Don't try to derive an age key from an ssh host key — sshd isn't
        # enabled on these machines, so /etc/ssh/ssh_host_ed25519_key
        # doesn't exist and the default would just error.
        sshKeyPaths = [];
      };

      # ssh private keys, dropped straight into ~/.ssh with the right mode.
      # `ssh/lab_pc` is the key the /mnt/lab sshfs mount and the `lab` alias
      # already point at.
      secrets =
        listToAttrs (map (name:
          nameValuePair "ssh/${name}" {
            owner = config.users.users.emilis.name;
            inherit (config.users.users.emilis) group;
            path = "${config.users.users.emilis.home}/.ssh/${name}";
            mode = "0600";
          })
        cfg.sshKeys)
        // {
          # Read by scripts running as either emilis or cryolab, so it is
          # group-readable rather than owner-only like the ssh keys above.
          # root owns it because nothing needs to write it.
          "grafana/api_key" = {
            owner = "root";
            group = "lab-secrets";
            mode = "0440";
          };
        };
    };

    # The group that gates the shared secrets above. `cryolab` only exists on
    # the DAQ laptop, so it joins from shared/users/cryolab/default.nix (only
    # imported there) instead of being named here — referencing
    # config.users.users.cryolab from this always-on module would fail to
    # evaluate on every other host.
    users.groups.lab-secrets = {};
    users.users.emilis.extraGroups = ["lab-secrets"];

    # Host-specific secrets, if this machine ever needs any that the others
    # must not be able to read. Create secrets/hosts/<host>.yaml, add a
    # matching rule to .sops.yaml, then:
    #
    #   sops.secrets."something" = {
    #     sopsFile = ../../../secrets/hosts/${hostName}.yaml;
    #   };

    environment.systemPackages = with pkgs; [
      sops # edit the encrypted files: `sops secrets/common.yaml`
      age # age-keygen, for creating the key in step 2
      ssh-to-age # if you ever want to reuse an ssh key as an age key
    ];
  };
}
