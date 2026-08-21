{pkgs, ...}: let
  # nixpkgs installs xarchiver's .tap into xarchiver's own output, but
  # thunar-archive-plugin has its tap directory baked in at build time and only
  # ever looks in its own $out/libexec (where nixpkgs ships taps for ark,
  # engrampa and file-roller — not xarchiver). Drop the tap in so the plugin
  # can actually find its backend.
  thunar-archive-plugin-xarchiver = pkgs.thunar-archive-plugin.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        install -Dm755 ${pkgs.xarchiver}/libexec/thunar-archive-plugin/xarchiver.tap \
          $out/libexec/thunar-archive-plugin/xarchiver.tap
      '';
  });
in {
  programs.thunar = {
    enable = true;
    plugins = [
      thunar-archive-plugin-xarchiver # create/extract archives from the right-click menu
      pkgs.thunar-volman # auto-handle USB drives / removable media
    ];
  };

  environment.systemPackages = with pkgs; [
    xarchiver # backend archive manager thunar-archive-plugin shells out to
    # xarchiver is only a GUI over these; without them it can list an archive
    # but not unpack or create one.
    unzip
    zip
    p7zip
  ];

  # The plugin picks its backend by looking up the default application for the
  # archive's mime type and loading "<desktop-id>.tap" — so anything not
  # pointed at xarchiver.desktop silently yields no extract menu.
  xdg.mime.defaultApplications = let
    xarchiver = ["xarchiver.desktop"];
  in {
    "application/zip" = xarchiver;
    "application/x-7z-compressed" = xarchiver;
    "application/vnd.rar" = xarchiver;
    "application/x-rar-compressed" = xarchiver;
    "application/x-tar" = xarchiver;
    "application/gzip" = xarchiver;
    "application/x-compressed-tar" = xarchiver;
    "application/x-bzip-compressed-tar" = xarchiver;
    "application/x-xz-compressed-tar" = xarchiver;
    "application/zstd" = xarchiver;
    "application/x-zstd-compressed-tar" = xarchiver;
  };

  services.gvfs.enable = true; # mounting, trash://, smb/sftp network shares
  services.tumbler.enable = true; # thumbnails (images, video, pdf)
}
