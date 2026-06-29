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
    ./features/libreoffice.nix
    ./features/mattermost.nix
    # ./features/bash_ct.nix
    ./features/flameshot.nix
  ];

  xsession = {
    windowManager.i3 = {
      config = {
        startup = [
          {command = "i3-msg 'workspace $ws10; exec firefox -new-window outlook.office.com/mail/'";}
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
        for_window [class="*.py"] floating enable
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
        assign [class="Org.gnome.Nautilus"] $ws5

      '';
    };
  };

  programs.i3status.enable = false;

  # CERN DFS (WebDAV) shortcut in the Thunar/GTK sidebar — same as the
  # davs:// link you used in Nautilus. gvfs prompts for your CERN
  # credentials on connect; nothing is stored in this repo.
  xdg.configFile."gtk-3.0/bookmarks".text = ''
    davs://dfs.cern.ch/dfs/ CERN DFS
  '';

  home.packages = with pkgs; [
    picom
    i3lock
    feh
    (polybar.override {
      i3Support = true;
      pulseSupport = true;
    })
  ];
}
