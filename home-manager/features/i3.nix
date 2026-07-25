{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  modifier = "Mod1"; # alt
  second_mod = "Mod4"; # win key

  # Single entry point for locking. Falls back to plain i3lock on a fresh
  # machine where the betterlockscreen cache doesn't exist yet. On hosts
  # with a fingerprint reader (services.fprintd + enrolled finger) it also
  # watches fprintd-verify while locked, so touching the sensor unlocks
  # without having to press Enter first (i3lock only starts PAM - and with
  # it the fingerprint scan - on submit).
  lockScreen = pkgs.writeShellScriptBin "lock-screen" ''
    export PATH=${makeBinPath [pkgs.procps pkgs.gnugrep pkgs.coreutils]}:/run/current-system/sw/bin:$PATH

    flag=$(mktemp -u /tmp/lock-screen-fprint.XXXXXX)

    fprint_watch() {
        command -v fprintd-verify >/dev/null 2>&1 || return 0
        fprintd-list "$USER" 2>/dev/null | grep -q '#' || return 0
        sleep 0.5 # let the locker window come up
        while pgrep -x i3lock-color >/dev/null || pgrep -x i3lock >/dev/null; do
            if fprintd-verify >/dev/null 2>&1; then
                touch "$flag"
                pkill -x i3lock-color 2>/dev/null
                pkill -x i3lock 2>/dev/null
                return 0
            fi
            sleep 1
        done
    }

    fprint_watch &
    watcher=$!

    # a locker killed by the fingerprint watcher exits non-zero; the flag
    # tells that apart from betterlockscreen failing to start
    ${pkgs.betterlockscreen}/bin/betterlockscreen -l dim \
        || { [ -e "$flag" ] || ${pkgs.i3lock}/bin/i3lock -n -c 000000; }

    kill "$watcher" 2>/dev/null
    rm -f "$flag"
  '';
in {
  imports = [./polybar.nix];

  xsession = {
    enable = true;
    numlock.enable = true; # numlockx on at session start
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
            # sddm autologin drops straight into the session, so lock right
            # away; boot then ends at the lockscreen while the apps below
            # start behind it.
            command = "${lockScreen}/bin/lock-screen";
            notification = false;
          }
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
            # polybar runs as a systemd user service (features/polybar.nix);
            # restarting here re-launches the per-monitor bars on i3 restart
            command = "systemctl --user restart polybar.service";
            always = true;
            notification = false;
          }
        ];
        bars = [];
        modifier = "${modifier}";
        fonts = {
          names = ["pango:JetBrainsMono Nerd Font"];
          size = 13.0;
        };
        floating.modifier = "Mod1";
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

          # keysym is lowercase "space" - "Space" doesn't exist and i3 drops
          # the binding silently
          "${modifier}+space" = "floating toggle";

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
          "${modifier}+Shift+e" = "exec --no-startup-id ${lockScreen}/bin/lock-screen";
          "${modifier}+d" = "exec rofi -show drun";
          "${modifier}+c" = "exec rofi -show calc";
          "${modifier}+o" = "exec rofi -show bookmarks"; # o(pen) a web bookmark on ws1
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

      # Firefox exposes only the page title, so match on that. i3 re-runs
      # for_window on title changes, so this also fires when an already-open
      # window navigates to naruto-arena.site/ingame.
      extraConfig = ''
        for_window [title="^In-Game - Naruto Arena"] floating enable
      '';
    };
  };

  programs.i3status.enable = false;

  # Registers as the logind lock handler via xss-lock, so
  # `loginctl lock-session` (used by the rofi power menu's "Lock screen")
  # actually locks, and the screen locks before suspend. Without this the
  # lock signal is silently dropped.
  services.screen-locker = {
    enable = true;
    lockCmd = "${lockScreen}/bin/lock-screen";
    xautolock.enable = false; # no idle auto-lock, only explicit lock + suspend
    xss-lock.extraOptions = ["--transfer-sleep-lock"];
  };

  home.packages = with pkgs; [
    picom
    i3lock
    betterlockscreen
    feh
    arandr # drag-and-drop monitor layout GUI
    lockScreen
  ];
}
