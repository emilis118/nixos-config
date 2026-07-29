# Data-acquisition laptop for the cryo lab. Not a personal machine: `cryolab`
# is the account the lab uses (autologin, KDE), mine is only for admin. It is
# meant to sit next to a setup with the lid shut and stay reachable, which is
# most of what makes this host different from work_laptop.
{
  lib,
  pkgs,
  ...
}: {
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
  # Autologin means nobody types a password at login, so kwallet could never
  # be unlocked by PAM anyway, and Plasma would pop up a "create a wallet"
  # dialog the first time something asked for it. Nothing here keeps secrets
  # in a wallet, so switch the subsystem off: kwalletrc as a system-wide
  # default (/etc/xdg is in XDG_CONFIG_DIRS), which is what kwalletd and every
  # KWallet client check before doing anything, plus the two PAM modules
  # plasma6.nix turns on unconditionally so nothing tries to unlock a wallet
  # at login either.
  #
  # The packages themselves stay: plasma6.nix has kwallet, kwallet-pam and
  # kwalletmanager in its *required* list, which environment.plasma6.
  # excludePackages does not filter. Disabled, they are dead weight in the
  # system profile, not a running daemon.
  #
  # Consequence: plasma-nm (wifi passwords) stores secrets in plain text under
  # ~/.config instead — fine on this machine, would not be on a personal one.
  environment.etc."xdg/kwalletrc".text = ''
    [Wallet]
    Enabled=false
  '';
  security.pam.services.login.kwallet.enable = lib.mkForce false;
  security.pam.services.kde.kwallet.enable = lib.mkForce false;

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
