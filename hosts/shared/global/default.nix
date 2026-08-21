{...}: {
  imports = [
    ./base_config.nix
    ./boot.nix
    ./shutdown.nix
    ./nix.nix
    ./locale.nix
    ./fonts.nix
    ./zsh.nix
    # both are inert until a host sets secrets.enable / nordvpn.enable
    ./secrets.nix
    ./nordvpn.nix
    # the desktop session is *not* global: each host imports either
    # optional/i3.nix (which brings thunar with it) or optional/kde.nix,
    # because both claim services.displayManager.defaultSession.
    ./../users/emilis # home-manager
  ];
}
