{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  modifier = "Mod1"; # alt
  second_mod = "Mod4"; # win key
in {
  xsession = {
    enable = true;
    windowManager.i3 = {
      enable = true;
      package = pkgs.i3; # or pkgs.i3-gaps, etc.
      # bindsym $mod+Shift+e exec "i3-nagbar -t warning -m 'You pressed the exit shortcut. Do you really want to exit i3? This will end your X session.' -B 'Yes, exit i3' 'i3-msg exit'"

      config = {
        # assigns = {
        #   "$ws1" = [{class = "^Firefox$";}];
        #   "$ws9" = [{class = "Org.gnome.Nautilus";} {class = "mattermost";}];
        # };
        startup = [
          {
            command = "picom";
            always = true;
          }
          {
            command = "random-wallpaper";
            always = true;
          }
          {command = "i3-msg 'workspace $ws1; exec firefox'";}
          {command = "i3-msg 'workspace $ws2; exec alacritty'";}
          {
            command = "/etc/nixos/dotfiles/i3/polybar.sh";
            always = true;
          }
        ];
        bars = [];
        modifier = "${modifier}";
        fonts = {
          names = ["pango:JetBrainsMono Nerd Font"];
          size = 13.0;
        };
        # floating.modifier = "Mod1"
        keybindings = {
          # make like vim
          "${modifier}+h" = "focus left";
          "${modifier}+j" = "focus down";
          "${modifier}+k" = "focus up";
          "${modifier}+l" = "focus right";
          # or arrows
          "${modifier}+Left" = "focus left";
          "${modifier}+Down" = "focus down";
          "${modifier}+Up" = "focus up";
          "${modifier}+Right" = "focus right";
          # move window

          # make like vim
          "${modifier}+Shift+h" = "move left";
          "${modifier}+Shift+j" = "move down";
          "${modifier}+Shift+k" = "move up";
          "${modifier}+Shift+l" = "move right";
          # or arrows
          "${modifier}+Shift+Left" = "move left";
          "${modifier}+Shift+Down" = "move down";
          "${modifier}+Shift+Up" = "move up";
          "${modifier}+Shift+Right" = "move right";

          # change focus between output (same monitor)
          "${modifier}+${second_mod}+h" = "focus output left";
          "${modifier}+${second_mod}+j" = "focus output down";
          "${modifier}+${second_mod}+k" = "focus output up";
          "${modifier}+${second_mod}+l" = "focus output right";

          # move workspaces between monitors
          "${modifier}+Shift+${second_mod}+h" = "move workspace to output left";
          "${modifier}+Shift+${second_mod}+j" = "move workspace to output down";
          "${modifier}+Shift+${second_mod}+k" = "move workspace to output up";
          "${modifier}+Shift+${second_mod}+l" = "move workspace to output right";

          # split window horizontally / vertically
          "${modifier}+b" = "split h";
          "${modifier}+v" = "split v";
          "${modifier}+f" = "fullscreen toggle";

          "${modifier}+Space" = "floating toggle";

          "${modifier}+1" = "workspace $ws1";
          "${modifier}+2" = "workspace $ws2";
          "${modifier}+3" = "workspace $ws3";
          "${modifier}+4" = "workspace $ws4";
          "${modifier}+5" = "workspace $ws5";
          "${modifier}+6" = "workspace $ws6";
          "${modifier}+7" = "workspace $ws7";
          "${modifier}+8" = "workspace $ws8";
          "${modifier}+9" = "workspace $ws9";
          "${modifier}+0" = "workspace $ws10";

          "${modifier}+Shift+1" = "move container to workspace $ws1";
          "${modifier}+Shift+2" = "move container to workspace $ws2";
          "${modifier}+Shift+3" = "move container to workspace $ws3";
          "${modifier}+Shift+4" = "move container to workspace $ws4";
          "${modifier}+Shift+5" = "move container to workspace $ws5";
          "${modifier}+Shift+6" = "move container to workspace $ws6";
          "${modifier}+Shift+7" = "move container to workspace $ws7";
          "${modifier}+Shift+8" = "move container to workspace $ws8";
          "${modifier}+Shift+9" = "move container to workspace $ws9";
          "${modifier}+Shift+0" = "move container to workspace $ws10";

          "${modifier}+Return" = "exec alacritty";
          "${modifier}+Shift+q" = "kill";
          "${modifier}+Shift+r" = "restart";
          # "${modifier}+Shift+e" = "exec i3-msg exit";
          "${modifier}+Shift+e" = "exec --no-startup-id betterlockscreen -l dim";
          "${modifier}+d" = "exec rofi -show drun";
          "${modifier}+c" = "exec rofi -show calc";
          "${modifier}+r" = "mode \"resize\"";
          "Print" = "exec flameshot gui";
        };
        # define modes / keybindings
        modes = {
          resize = {
            Down = "resize grow height 10 px or 10 ppt";
            Escape = "mode default";
            Left = "resize shrink width 10 px or 10 ppt";
            Return = "mode default";
            Right = "resize grow width 10 px or 10 ppt";
            Up = "resize shrink height 10 px or 10 ppt";
          };
        };
        workspaceAutoBackAndForth = true;
      };
    };
  };

  programs.i3status.enable = false;

  home.packages = with pkgs; [
    picom
    i3lock
    betterlockscreen
    feh
    (polybar.override {
      i3Support = true;
      pulseSupport = true;
    })
  ];
}
