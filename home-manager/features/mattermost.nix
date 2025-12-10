{pkgs, ...}: {
  home.packages = [
    pkgs.mattermost-desktop
    pkgs.xdg-utils
  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
  xdg.portal.config = {
    common = {
      default = [
        "gtk"
      ];
    };
  };
}
