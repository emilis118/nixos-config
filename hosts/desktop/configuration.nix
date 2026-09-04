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

  # Enable OpenGL
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false; # for older than rtx-20 series
    nvidiaSettings = true;
    # package = config.boot.kernelPackages.nvidiaPackages.stable;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  secrets.enable = true;

  # NordLynx. Off at boot (nordvpn.autoStart stays false) — `vpn up`, the
  # polybar shield, or mod+d → vpn-menu brings it up.
  nordvpn.enable = true;
  # blocky is this host's resolver (networking.nameservers = 127.0.0.1), so
  # don't let wg-quick swap in Nord's DNS and bypass the blocklists.
  nordvpn.dns = [];

  # Persist the NVIDIA driver's compiled-shader cache. On NVIDIA these vars
  # govern the on-disk ISA cache for BOTH OpenGL and Vulkan. By default the
  # cache is size-limited and the driver's cleanup pass evicts entries, so a
  # big shader set like CS2's gets trimmed between sessions and has to be
  # rebuilt on every launch (the slow "Building Vulkan shaders" screen).
  # SKIP_CLEANUP keeps entries, and the larger size gives them room to live.
  # Set at session scope (not just Steam launch options) so Steam's separate
  # background shader-processing pass benefits too.
  #
  # These are the cache that actually works on this driver. Steam's own
  # fossilize pre-caching pass is a separate, worse thing and is turned OFF in
  # the Steam client - see the shader note in home-manager/features/cs2.nix.
  environment.sessionVariables = {
    __GL_SHADER_DISK_CACHE = "1";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "12000000000"; # ~12 GB
  };
  system.stateVersion = "24.11"; # Did you read the comment?
}
