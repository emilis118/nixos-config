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
    ./features/thunderbird.nix
  ];

  xsession = {
    windowManager.i3 = {
      config = {
        startup = [
          {command = "i3-msg 'workspace $ws10; exec firefox -new-window outlook.office.com/mail/'";}
        ];
      };
      # Single internal display: keep the same workspace layout as work_pc
      # but don't pin workspaces to external outputs (HDMI-2/DP-3). When
      # docked, external monitors are picked up automatically.
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

        assign [class="Mattermost"] $ws9
        assign [class="whatsapp-electron"] $ws9
        assign [class="Org.gnome.Nautilus"] $ws5
        # remote desktops (rofi "remote" tab) land next to the local VMs
        assign [class="org\.remmina\.Remmina"] $ws4

        for_window [title="LHC Page 1"] floating enable

        bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +5%
        bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%-
      '';
    };
  };

  polybarModules = {
    # off while the beam is down (LS3); flip when the LHC is back
    lhc = false;
    battery = true;
    backlight = true;
  };

  home.packages = [pkgs.brightnessctl];

  # CERN DFS (WebDAV) shortcut in the Thunar/GTK sidebar — same as the
  # davs:// link you used in Nautilus. gvfs prompts for your CERN
  # credentials on connect; nothing is stored in this repo.
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    davs://dfs.cern.ch/dfs/ CERN DFS
  '';
}
