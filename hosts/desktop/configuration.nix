# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./../shared/global # auto picks default.nix
    ./../shared/optional/i3.nix # sddm + i3 session
    ./../shared/optional/nvidia.nix # driver + shader cache, shared with the other desktop
    # Both session modules, which optional/kde.nix warns against, because this
    # machine is shared: ieva gets Plasma, I get i3, and sddm lists both. The
    # warning is about the two of them claiming defaultSession, so this host
    # settles that explicitly below instead of leaving it to import order.
    ./../shared/optional/kde.nix # plasma 6 on wayland, for ieva
    ./../shared/optional/blocky.nix
    ./../shared/optional/steam.nix
    ./../shared/optional/razer.nix
    ./../shared/users/ieva # emilis comes from shared/global
  ];

  # Networking
  networking.hostName = "desktop";

  # ieva is the account the machine boots into. optional/i3.nix sets both of
  # these to emilis/none+i3 for the hosts where I'm the only user, so override
  # rather than duplicate. mkForce is needed on defaultSession specifically:
  # i3.nix assigns it outright (plasma6 only mkDefaults it), so a plain
  # assignment here would be a conflict, not a win.
  #
  # Consequence worth knowing: boot lands in ieva's Plasma session every time.
  # To get to i3, log out (or switch user) and pick it in sddm's session menu.
  #
  # Session takes the .desktop filename — that is what the sddm module itself
  # generates for services.displayManager.autoLogin, and "plasma" is the
  # Wayland session, the one plasma6 defaults to.
  services.displayManager.defaultSession = lib.mkForce "plasma";
  services.displayManager.sddm.settings.Autologin = {
    User = lib.mkForce "ieva";
    Session = lib.mkForce "plasma.desktop";
  };

  secrets.enable = true;

  # NordLynx. Off at boot (nordvpn.autoStart stays false) — `vpn up`, the
  # polybar shield, or mod+d → vpn-menu brings it up.
  nordvpn.enable = true;
  # blocky is this host's resolver (networking.nameservers = 127.0.0.1), so
  # don't let wg-quick swap in Nord's DNS and bypass the blocklists.
  nordvpn.dns = [];

  system.stateVersion = "24.11"; # Did you read the comment?
}
