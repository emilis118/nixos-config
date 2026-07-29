{
  config,
  lib,
  osConfig,
  ...
}:
with lib; let
  home = config.home.homeDirectory;

  # Which private keys sops-nix actually drops into ~/.ssh on this machine —
  # see `secrets.sshKeys` in hosts/shared/global/secrets.nix. Read through
  # osConfig rather than duplicated here, so the list of keys a host installs
  # and the list of hosts it knows how to reach can't drift apart.
  #
  # A block whose key is missing would be worse than no block at all: ssh
  # would stop before trying anything else with "no such identity", so each
  # entry below is emitted only on the machines that have its key.
  installed =
    if osConfig ? secrets && osConfig.secrets.enable
    then osConfig.secrets.sshKeys
    else [];

  # <key name in secrets/common.yaml> -> the blocks that key unlocks.
  # IdentityFile/IdentitiesOnly are filled in below; IdentitiesOnly matters
  # because the agent started by dotfiles/.zshrc will otherwise offer every
  # loaded key and a strict server can hit MaxAuthTries before the right one.
  keyed = {
    lab_pc."lab" = {
      HostName = "pxicryolab05.cern.ch";
      User = "cryolab";
      # the box is on the far side of a flaky VPN more often than not
      ServerAliveInterval = 15;
    };
    github."github.com" = {
      HostName = "github.com";
      User = "git";
    };
    gitlab."gitlab.cern.ch" = {
      HostName = "gitlab.cern.ch";
      User = "git";
    };
  };

  # Reachable with a password rather than a key, so it needs no gating:
  # not everyone who has to get into the DAQ laptop will have put a key on
  # it first (see remote-access.nix, README "daq-laptop").
  keyless."daq" = {
    HostName = "lapte234119.local";
    User = "cryolab";
  };

  withIdentity = key:
    mapAttrs (_: block:
      block
      // {
        IdentityFile = "${home}/.ssh/${key}";
        IdentitiesOnly = true;
      });

  blocks =
    keyless
    // foldl' mergeAttrs {}
    (map (key: withIdentity key keyed.${key})
      (filter (key: keyed ? ${key}) installed));
in {
  # ~/.ssh/config, generated so that `ssh lab` picks the right key on its own
  # instead of every call site repeating `-i ~/.ssh/lab_pc`. Host *keys* come
  # from sops (secrets.sshKeys); this is only the routing table that says
  # which one to present where.
  #
  # Imported by features/cli, so it reaches the daq-laptop profiles too —
  # they have no secrets, so they get the keyless blocks and nothing else.
  programs.ssh = {
    enable = true;

    # home-manager 26.05 still injects a legacy `Host *` block and warns
    # about it. Opting out and writing the defaults we actually want keeps
    # `nix flake check` quiet and the generated file readable.
    enableDefaultConfig = false;

    settings =
      blocks
      // {
        "*" = {
          # keys are per-host and never forwarded onward
          ForwardAgent = false;
          # the agent from dotfiles/.zshrc is per-login; letting ssh add the
          # key on first use is what makes one passphrase prompt per session
          AddKeysToAgent = "yes";
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
        };
      };
  };
}
