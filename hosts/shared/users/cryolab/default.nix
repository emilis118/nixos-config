{pkgs, ...}: {
  # The lab's account on the DAQ machine — shared by whoever is running the
  # measurement, unlike users/emilis. No `wheel`: administering the box is
  # done from the emilis account (or over ssh).
  users.users.cryolab = {
    isNormalUser = true;
    description = "Cryolab DAQ";
    shell = pkgs.zsh;
    # Only used the first time the account is created; change it on the
    # machine with `passwd`. It is also the ssh password until then, so
    # don't leave it at this on a networked machine.
    initialPassword = "cryolab";
    home = "/home/cryolab";
    extraGroups = [
      "networkmanager"
      # instruments on USB-serial adapters (/dev/ttyUSB*, /dev/ttyACM*)
      "dialout"
      "video"
      "audio"
    ];
  };
}
