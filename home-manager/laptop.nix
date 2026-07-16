{pkgs, ...}: {
  imports = [
    ./global # default.nix
    ./features/discord.nix
    ./features/postman.nix
    ./features/qemu.nix
    ./features/cli/ani-cli.nix
    ./features/cs2.nix
    ./features/minecraft.nix
    ./features/sound.nix
    ./features/wallpaper.nix
    ./features/i3.nix
    ./features/flameshot.nix
  ];

  polybarModules = {
    battery = true;
    backlight = true;
  };

  home.packages = [pkgs.brightnessctl];

  # Single internal display: same layout as desktop but no xrandr pinning.
  xsession = {
    windowManager.i3 = {
      extraConfig = ''
        set $ws1 "1:Firefox"
        set $ws2 "2:Terminal"
        set $ws3 "3:Game"
        set $ws4 "4:VM"
        set $ws5 "5:Postman"
        set $ws6 "6"
        set $ws7 "7:Steam"
        set $ws8 "8:Bluetooth"
        set $ws9 "9:Discord"
        set $ws10 "10:Spotify"

        for_window [class=".*"] border none
        for_window [class=".*\.py"] floating enable

        assign [class="net-runelite-client-RuneLite"] $ws4
        assign [class="discord"] $ws9
        assign [class="^bluetuith$"] $ws8
        assign [class="Postman"] $ws5
        assign [class="cs2"] $ws3
        assign [class="^Minecraft"] $ws3
        assign [class="steam"] $ws7

        bindsym Mod1+Shift+f exec firefox
        # start-discord comes from hosts/shared/optional/i3.nix
        bindsym Mod1+Shift+d exec "start-discord"

        bindsym XF86AudioRaiseVolume exec --no-startup-id pamixer -i 5
        bindsym XF86AudioLowerVolume exec --no-startup-id pamixer -d 5
        bindsym XF86AudioMute exec --no-startup-id pamixer -t

        bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +5%
        bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%-
      '';
    };
  };
}
