{pkgs, ...}: {
  # OpenRazer: driver + userspace daemon for Razer devices such as the
  # DeathAdder. Broader model coverage than libratbag/Piper, at the cost of
  # a DKMS kernel module that rebuilds on kernel updates.
  hardware.openrazer = {
    enable = true;
    # Add the user to the "openrazer" group so it can talk to the daemon.
    users = ["emilis"];
  };

  # Polychromatic is the GUI front-end for OpenRazer. Open it, select the
  # DeathAdder, and set the DPI there. OpenRazer reapplies the setting when
  # the daemon starts, so it persists across reboots.
  environment.systemPackages = [pkgs.polychromatic];
}
