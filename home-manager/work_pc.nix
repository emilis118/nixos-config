{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./global # default.nix
    ./features/qemu.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/remote.nix
    ./features/onlyoffice.nix
    ./features/mattermost.nix
    # ./features/bash_ct.nix
    ./features/flameshot.nix
    ./features/whatsapp.nix
    ./features/marketplace-notifications
    ./features/thunderbird.nix
  ];

  xsession = {
    windowManager.i3 = {
      config = {
        startup = [
          {command = "i3-msg 'workspace $ws10; exec thunderbird'";}
          {
            command = "xrandr --output HDMI-2 --primary --right-of DP-3";
            always = true;
          }
        ];
      };
      extraConfig = ''
        set $ws1 "1:Firefox"
        set $ws2 "2:Terminal"
        set $ws3 "3"
        set $ws4 "4:VM"
        set $ws5 "5"
        set $ws6 "6"
        set $ws7 "7"
        set $ws8 "8"
        set $ws9 "9:MM"
        set $ws10 "10:Email"

        for_window [class=".*"] border none
        for_window [class=".*\.py"] floating enable
        workspace $ws1 output HDMI-2
        workspace $ws2 output HDMI-2
        workspace $ws3 output HDMI-2
        workspace $ws4 output HDMI-2
        workspace $ws5 output HDMI-2
        workspace $ws6 output HDMI-2
        workspace $ws7 output HDMI-2
        workspace $ws8 output DP-3
        workspace $ws9 output DP-3
        workspace $ws10 output DP-3

        assign [class="Mattermost"] $ws9
        assign [class="whatsapp-electron"] $ws9
        assign [class="thunderbird"] $ws10
        assign [class="Org.gnome.Nautilus"] $ws5

        for_window [title="LHC Page 1"] floating enable
      '';
    };
  };

  # off while the beam is down (LS3); flip when the LHC is back
  polybarModules.lhc = false;
  polybarModules.marketplace = true;

  # CERN DFS (WebDAV) shortcut in the Thunar/GTK sidebar — same as the
  # davs:// link you used in Nautilus. gvfs prompts for your CERN
  # credentials on connect; nothing is stored in this repo.
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    davs://dfs.cern.ch/dfs/ CERN DFS
  '';
}
