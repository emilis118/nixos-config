{...}: {
  imports = [
    ./base_config.nix
    ./boot.nix
    ./nix.nix
    ./locale.nix
    ./fonts.nix
    ./zsh.nix
    # both are inert until a host sets secrets.enable / nordvpn.enable
    ./secrets.nix
    ./nordvpn.nix
    ./../optional/i3.nix
    ./../optional/thunar.nix
    ./../users/emilis # home-manager
  ];
}
