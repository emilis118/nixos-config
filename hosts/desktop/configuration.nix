# Ieva's machine. Plasma 6 on Wayland is the only session: no i3 and no
# blocky. My account stays for administering it, the same split as
# daq-laptop/cryolab, and its home profile (home-manager/desktop.nix) is
# just the shell.
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
    ./../shared/optional/kde.nix # plasma 6 on wayland + sddm (brings dolphin)
    ./../shared/optional/nvidia.nix # driver + shader cache, shared with the other desktop
    ./../shared/optional/steam.nix
    ./../shared/optional/razer.nix
    ./../shared/users/ieva # emilis comes from shared/global
  ];

  # Networking
  networking.hostName = "desktop";

  # Boot straight into Ieva's Plasma session. defaultSession stays what
  # plasma6 sets ("plasma", the Wayland one).
  services.displayManager.autoLogin = {
    enable = true;
    user = "ieva";
  };
  # Autologin means PAM never sees a password, so kwallet can't be unlocked
  # at login. Chrome stores its passwords in kwallet under Plasma, so it would
  # ask for the wallet password every time it starts. Switched off the same
  # way as on daq-laptop (see the comment there): with kwallet disabled,
  # Chrome falls back to its own store. plasma-nm keeps wifi passwords in
  # plain text under ~/.config as a result.
  environment.etc."xdg/kwalletrc".text = ''
    [Wallet]
    Enabled=false
  '';
  security.pam.services.login.kwallet.enable = lib.mkForce false;
  security.pam.services.kde.kwallet.enable = lib.mkForce false;

  # US, Lithuanian, French. Win+Space cycles through them (the option comes
  # from global/base_config.nix). This is the system-wide X11 default; the
  # Plasma session reads ~/.config/kxkbrc instead, which
  # home-manager/desktop-ieva.nix sets to the same list.
  services.xserver.xkb.layout = lib.mkForce "us,lt,fr";

  # Chrome opens web links and PDFs. These are system defaults
  # (/etc/xdg/mimeapps.list), not home-manager's xdg.mimeApps: that one makes
  # ~/.config/mimeapps.list a read-only store symlink, and Plasma's "Default
  # Applications" page and Chrome's "make default" button both write there.
  # Anything chosen there still wins over these.
  xdg.mime.defaultApplications = let
    chrome = ["google-chrome.desktop"];
  in {
    "application/pdf" = chrome;
    "text/html" = chrome;
    "x-scheme-handler/http" = chrome;
    "x-scheme-handler/https" = chrome;
  };

  # the mouse is Ieva's to set up in Polychromatic too
  hardware.openrazer.users = ["ieva"];

  secrets.enable = true;

  # NordLynx. Off at boot (nordvpn.autoStart stays false); `vpn up` from my
  # account brings it up. No blocky here anymore, so it uses Nord's DNS
  # while connected (the module default).
  nordvpn.enable = true;

  system.stateVersion = "24.11"; # Did you read the comment?
}
