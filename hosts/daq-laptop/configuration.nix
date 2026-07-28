# Data-acquisition laptop for the cryo lab. Not a personal machine: `cryolab`
# is the account the lab uses (autologin, KDE), mine is only for admin. It is
# meant to sit next to a setup with the lid shut and stay reachable, which is
# most of what makes this host different from work_laptop.
{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../shared/global # auto picks default.nix
    ./../shared/optional/kde.nix # plasma 6 on wayland + sddm
    ./../shared/optional/remote-access.nix # sshd, KRDP's port, mdns
    ./../shared/users/cryolab # the lab's account (emilis comes from global)
  ];

  # Networking
  networking.hostName = "lapte234119";

  hardware.graphics.enable = true;
  hardware.enableAllFirmware = true;

  # Log the lab straight into Plasma at boot, so the machine comes back on
  # its own after a power cut with nobody in the room. defaultSession stays
  # what plasma6 sets ("plasma", the Wayland one).
  services.displayManager.autoLogin = {
    enable = true;
    user = "cryolab";
  };
  # Autologin means nobody types a password at login, so kwallet can't be
  # unlocked by PAM and Plasma will ask for it the first time something wants
  # the wallet. Give the wallet an empty password when it offers to, or
  # delete it — nothing here stores secrets in it.

  # shared/optional/laptop.nix is deliberately *not* imported. It suspends and
  # then hibernates on lid close, which on a machine that is supposed to keep
  # acquiring data with the lid shut (and stay reachable over ssh/RDP) is
  # exactly wrong. The parts that do apply are below.
  services.libinput.enable = true;
  services.thermald.enable = true;
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };
  # Idle suspend would take the machine off the network mid-run. Plasma's own
  # power settings (System Settings -> Power Management) sit on top of this
  # per user, so also set "never sleep" there for cryolab.
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  environment.systemPackages = with pkgs; [
    firefox # KDE ships no browser
    lm_sensors
    htop
    usbutils # lsusb, for finding an instrument that isn't showing up
    pciutils
    minicom # talk to a serial instrument before there's software for it
  ];

  # No DAQ software stack yet — when there is one it goes in its own
  # hosts/shared/optional/ module, not here.

  system.stateVersion = "26.05"; # Did you read the comment?
}
