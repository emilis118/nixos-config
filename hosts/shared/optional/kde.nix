{pkgs, ...}: {
  # Plasma 6 on Wayland, the alternative to optional/i3.nix. A host imports
  # one or the other, never both: they both set
  # services.displayManager.defaultSession.
  #
  # Almost everything comes from the plasma6 module's own defaults — it
  # already turns on sddm, sddm.wayland (kwin as the greeter compositor) and
  # sets defaultSession = "plasma", the Wayland session. That default is worth
  # keeping rather than switching to "plasmax11": KRDP, Plasma's built-in RDP
  # server (optional/remote-access.nix), only works in a Wayland session.
  # X11 programs still run under XWayland.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.autoNumlock = true;

  environment.systemPackages = with pkgs; [
    kdePackages.kate # the editor Plasma's "open in text editor" expects
    kdePackages.filelight # what is eating the disk
  ];

  # optional/thunar.nix points every archive mime type at xarchiver, because
  # thunar-archive-plugin picks its backend from the default application. That
  # is a system-wide setting, so on a host importing both session modules
  # (hosts/desktop) it would drag Plasma's archives away from ark too. The mime
  # spec checks /etc/xdg/<desktop>-mimeapps.list before mimeapps.list, and
  # Plasma sets XDG_CURRENT_DESKTOP=KDE, so this wins inside a Plasma session
  # only — i3 keeps xarchiver, Plasma keeps ark. Harmless on a KDE-only host.
  environment.etc."xdg/kde-mimeapps.list".text = let
    ark =
      builtins.concatStringsSep "\n"
      (map (t: "${t}=org.kde.ark.desktop") [
        "application/zip"
        "application/x-7z-compressed"
        "application/vnd.rar"
        "application/x-rar-compressed"
        "application/x-tar"
        "application/gzip"
        "application/x-compressed-tar"
        "application/x-bzip-compressed-tar"
        "application/x-xz-compressed-tar"
        "application/zstd"
        "application/x-zstd-compressed-tar"
      ]);
  in ''
    [Default Applications]
    ${ark}
  '';
}
