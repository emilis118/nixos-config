{
  imports = [
    ./global # default.nix
    ./features/qemu.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/remote.nix
    ./features/onlyoffice.nix
    ./features/mattermost.nix
    ./features/flameshot.nix
    ./features/whatsapp.nix
    ./features/marketplace-notifications
    ./features/thunderbird.nix
    ./features/cern-dfs.nix
  ];

  # workspace names / window assignments live in features/i3-profile.nix
  i3Profile.work = true;

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
      # Two monitors: pin the workspaces to a specific output. The names and
      # window rules themselves come from the "work" i3Profile.
      extraConfig = ''
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
      '';
    };
  };

  # off while the beam is down (LS3); flip when the LHC is back
  polybarModules.lhc = false;
  polybarModules.marketplace = true;
}
