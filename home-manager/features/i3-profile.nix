{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.i3Profile;
in {
  # The per-host i3 bits that used to be copy-pasted into each
  # home-manager/<host>.nix: workspace names, window assignments and the
  # extra keybindings. Hosts opt into a profile instead, the same way they
  # opt into polybarModules / rofiModes.
  options.i3Profile = {
    personal = mkEnableOption "gaming/personal workspaces (Steam, Discord, WhatsApp, RuneLite, CS2)";
    work = mkEnableOption "work workspaces (Mattermost, WhatsApp, Thunderbird, Remmina)";
    laptopKeys = mkEnableOption "brightness keys (needs a backlight)";
  };

  config = {
    home.packages = mkIf cfg.laptopKeys [pkgs.brightnessctl];

    xsession.windowManager.i3.extraConfig = mkMerge [
      # shared by every host
      ''
        set $ws1 "1:Firefox"
        set $ws2 "2:Terminal"
        set $ws4 "4:VM"

        for_window [class=".*"] border none
        for_window [class=".*\.py"] floating enable
      ''

      (mkIf cfg.personal ''
        set $ws3 "3:Game"
        set $ws5 "5:Postman"
        set $ws6 "6"
        set $ws7 "7:Steam"
        set $ws8 "8"
        set $ws9 "9:Discord"
        set $ws10 "10:Spotify"

        for_window [class="net-runelite-client-RuneLite"] floating enable
        for_window [class="net-runelite-launcher-Launcher"] floating enable

        # Steam's friends list, chats and news popups are separate top-level
        # windows sharing the main window's WM_CLASS ("steamwebhelper",
        # "steam"), and a chat's title is only the friend's name — there is no
        # suffix to match on, so the title is the only discriminator: float
        # everything except the main window, whose title is exactly "Steam".
        #
        # The float rule has to exclude "Steam" itself rather than being
        # overridden by a later `floating disable`: i3 re-runs for_window on
        # every title change, but each rule fires at most once per window.
        # These CEF windows are mapped with the placeholder title "Steam" and
        # only get their real one a moment later, so an unconditional float
        # rule burns itself on the placeholder, the disable rule tiles the
        # window, and the real title arrives with no rule left to re-float it.
        # A rule that does not match the placeholder stays armed for it.
        for_window [class="^[Ss]team$" title="^(?!Steam$)"] floating enable
        for_window [class="^[Ss]team$" title="^Steam$"] floating disable

        assign [class="net-runelite-client-RuneLite"] $ws4
        assign [class="discord"] $ws9
        # shares the chat workspace with Discord, the same way the work
        # profile puts WhatsApp alongside Mattermost on its $ws9.
        assign [class="whatsapp-electron"] $ws9
        assign [class="Postman"] $ws5
        assign [class="cs2"] $ws3
        assign [class="^Minecraft"] $ws3
        # WM_CLASS comes from the --class in features/naruto-arena; chromium
        # capitalises the class half of the pair, hence the alternation. The
        # window sizes itself to the game's 770x560 stage and picks its own
        # position (one slot per account), which only holds while it floats —
        # tiled it would be stretched over half the screen around a stage that
        # does not grow with it.
        assign [class="^[Nn]aruto-arena$"] $ws3
        for_window [class="^[Nn]aruto-arena$"] floating enable
        assign [class="steam"] $ws7

        bindsym Mod1+Shift+f exec firefox
        # start-discord comes from hosts/shared/optional/i3.nix
        bindsym Mod1+Shift+d exec "start-discord"

        bindsym XF86AudioRaiseVolume exec --no-startup-id pamixer -i 5
        bindsym XF86AudioLowerVolume exec --no-startup-id pamixer -d 5
        bindsym XF86AudioMute exec --no-startup-id pamixer -t
      '')

      (mkIf cfg.work ''
        set $ws3 "3"
        set $ws5 "5"
        set $ws6 "6"
        set $ws7 "7"
        set $ws8 "8"
        set $ws9 "9:MM"
        set $ws10 "10:Email"

        assign [class="Mattermost"] $ws9
        assign [class="whatsapp-electron"] $ws9
        assign [class="thunderbird"] $ws10
        assign [class="Org.gnome.Nautilus"] $ws5
        # remote desktops (rofi "remote" tab) land next to the local VMs
        assign [class="org\.remmina\.Remmina"] $ws4

        for_window [title="LHC Page 1"] floating enable
      '')

      (mkIf cfg.laptopKeys ''
        bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set +5%
        bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 5%-
      '')
    ];
  };
}
