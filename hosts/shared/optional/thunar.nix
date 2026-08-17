{pkgs, ...}: {
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-archive-plugin # create/extract archives from the right-click menu
      thunar-volman # auto-handle USB drives / removable media
    ];
  };

  environment.systemPackages = [pkgs.xarchiver]; # backend archive manager thunar-archive-plugin shells out to

  services.gvfs.enable = true; # mounting, trash://, smb/sftp network shares
  services.tumbler.enable = true; # thumbnails (images, video, pdf)
}
