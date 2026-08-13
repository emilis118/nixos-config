{pkgs, ...}: {
  # Ieva's account on `desktop`. Plasma rather than i3, and no `wheel`:
  # administering the box is done from the emilis account, same split as
  # users/cryolab on the DAQ laptop.
  users.users.ieva = {
    isNormalUser = true;
    description = "Ieva";
    shell = pkgs.zsh; # global/zsh.nix enables it system-wide
    # Only used the first time the account is created, and it lands in the
    # world-readable nix store — change it on the machine with `passwd`.
    initialPassword = "123456";
    home = "/home/ieva";
    extraGroups = [
      "networkmanager"
      # optional/steam.nix turns on programs.gamemode, which only renices
      # games for members of this group.
      "gamemode"
    ];
  };
}
