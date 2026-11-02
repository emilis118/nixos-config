{
  imports = [
    ./roles/work.nix
    ./features/marketplace-notifications
    ./features/freecad.nix
  ];

  xsession = {
    windowManager.i3 = {
      config = {
        startup = [
          {command = "i3-msg 'workspace $ws10; exec thunderbird'";}
          {
            command = "xrandr --output DP-3 --primary --output HDMI-4 --right-of DP-3";
            always = true;
          }
        ];
      };
      # Two monitors: DP-3 (primary, left) and HDMI-4 (right). VM, 8, MM and
      # Email live on HDMI-4, everything else on DP-3. The names and
      # window rules themselves come from the "work" i3Profile.
      extraConfig = ''
        workspace $ws1 output DP-3
        workspace $ws2 output DP-3
        workspace $ws3 output DP-3
        workspace $ws4 output HDMI-4
        workspace $ws5 output DP-3
        workspace $ws6 output DP-3
        workspace $ws7 output DP-3
        workspace $ws8 output HDMI-4
        workspace $ws9 output HDMI-4
        workspace $ws10 output HDMI-4
      '';
    };
  };

  polybarModules.marketplace = true;
}
