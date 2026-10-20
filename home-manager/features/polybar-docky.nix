{
  config,
  pkgs,
  lib,
  ...
}:
# adi1090x's "Docky" polybar theme (github.com/adi1090x/polybar-themes,
# simple/docky) as an alternative to the main bar in polybar.nix, carrying
# every module that bar has. `polybar-docky` swaps it in for the session; the
# main bar comes back on `polybar-docky off`, on an i3 restart (whose startup
# restarts polybar.service) and on the next login, since nothing pulls this
# unit in by itself.
#
# What carried over from upstream: the floating bottom bar with the accent
# border, the launcher / power menu blocks at either end, workspace colours,
# and the scripts - rofi launcher, power menu with confirmation, and the colour
# switcher with its random and pywal variants. updates.sh is left out: it
# counts pacman updates, which NixOS has no equivalent of. The feather icon
# font is swapped for the Nerd Font glyphs the module scripts already print.
with lib; let
  cfg = config.polybarModules;
  main = config.services.polybar.settings;
  polybarPkg = config.services.polybar.package;

  rofiDir = ../../dotfiles/rofi/docky;
  paletteFile = "${config.xdg.stateHome}/polybar-docky/palette";

  # i3 ignores the position of dock windows - it stretches them across the
  # output and pins them to the edge - so the floating look needs
  # override-redirect, and the space the bar sits in is kept free with an
  # i3 bottom gap instead of a strut. `gaps ... all` sets i3's global default,
  # so workspaces created later get it too.
  barHeight = 40;
  border = 2;
  offset = 12;
  gap = barHeight + border + 2 * offset;
  popupY = barHeight + border + offset + 8;

  # Upstream's colour schemes (scripts/colors-{dark,light}.sh): an accent and
  # whether text drawn on it has to be dark to stay readable.
  accents = [
    ["amber" "#ffb300" true]
    ["blue" "#1e88e5" false]
    ["blue-gray" "#546e7a" false]
    ["brown" "#6d4c41" false]
    ["cyan" "#00acc1" true]
    ["deep-orange" "#f4511e" false]
    ["deep-purple" "#5e35b1" false]
    ["green" "#43a047" false]
    ["gray" "#757575" false]
    ["indigo" "#3949ab" false]
    ["blue-light" "#039be5" true]
    ["green-light" "#7cb342" true]
    ["lime" "#c0ca33" true]
    ["orange" "#fb8c00" true]
    ["pink" "#d81b60" false]
    ["purple" "#8e24aa" false]
    ["red" "#e53935" false]
    ["teal" "#00897b" false]
    ["yellow" "#fdd835" true]
  ];

  # Loads the palette the colour menu last wrote (upstream's dark red until
  # then). Only known keys holding a #rrggbb value are taken, so a mangled
  # file falls back to the defaults instead of breaking the bar.
  loadPalette = ''
    # shellcheck disable=SC2034 # not every script uses every colour
    {
        BG='#1F1F1F' FG='#FFFFFF' FGA='#8F8F8F' AC='#e53935' MF='#FFFFFF' SC='#E53935' AL='#7cb342'
        if [ -r "${paletteFile}" ]; then
            while IFS='=' read -r key value; do
                case "$key" in
                    BG | FG | FGA | AC | MF | SC | AL)
                        [[ "$value" =~ ^#[0-9A-Fa-f]{6}$ ]] && printf -v "$key" '%s' "$value"
                        ;;
                esac
            done <"${paletteFile}"
        fi
        rofi_colors="* { al: #00000000; bg: ''${BG}FF; bga: ''${AC}33; bar: ''${MF}FF; fg: ''${FG}FF; ac: ''${AC}FF; }"
    }
  '';

  # Run through `i3-msg exec` so the apps it starts belong to i3 rather than
  # to the bar's unit: switching back to the main bar stops that unit, and
  # everything still in it with it.
  launcherRofi = lib.getExe (pkgs.writeShellApplication {
    name = "polybar-docky-launcher-rofi";
    runtimeInputs = [config.home.profileDirectory];
    bashOptions = [];
    text = ''
      ${loadPalette}
      exec rofi -show drun -modi drun -display-drun "󰍉" -show-icons -drun-display-format "{name}" \
          -theme ${rofiDir}/menu.rasi -theme-str "$rofi_colors"
    '';
  });

  launcherScript = lib.getExe (pkgs.writeShellApplication {
    name = "polybar-docky-launcher";
    runtimeInputs = [pkgs.i3];
    bashOptions = [];
    text = ''
      exec i3-msg -q exec --no-startup-id ${launcherRofi}
    '';
  });

  # Upstream's powermenu.sh: pick an action, then confirm it by typing yes/no.
  # Lock is the session's lock-screen; suspend locks through xss-lock.
  powermenuScript = lib.getExe (pkgs.writeShellApplication {
    name = "polybar-docky-powermenu";
    runtimeInputs = [pkgs.procps pkgs.gnused pkgs.systemd pkgs.i3 config.home.profileDirectory];
    bashOptions = [];
    text = ''
      ${loadPalette}
      dir=${rofiDir}

      lock="󰌾  Lock"
      suspend="󰤄  Sleep"
      logout="󰍃  Logout"
      reboot="󰜉  Restart"
      shutdown="󰐥  Shutdown"

      confirmed() {
          ans=$(rofi -dmenu -i -p "Are You Sure? : " -theme "$dir/confirm.rasi" -theme-str "$rofi_colors")
          case "$ans" in
              yes | YES | y | Y) return 0 ;;
              no | NO | n | N) return 1 ;;
              *)
                  rofi -theme "$dir/message.rasi" -theme-str "$rofi_colors" \
                      -e "Available Options  -  yes / y / no / n"
                  return 1
                  ;;
          esac
      }

      uptime=$(uptime -p | sed -e 's/up //g')
      chosen=$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" |
          rofi -dmenu -p "Uptime: $uptime" -selected-row 0 \
              -theme "$dir/powermenu.rasi" -theme-str "$rofi_colors")

      case "$chosen" in
          "$lock") exec lock-screen ;;
          "$suspend") confirmed && systemctl suspend ;;
          "$logout") confirmed && i3-msg exit ;;
          "$reboot") confirmed && systemctl reboot ;;
          "$shutdown") confirmed && systemctl poweroff ;;
      esac
      exit 0
    '';
  });

  # Upstream's color-switch.sh, random.sh and pywal.sh in one menu. Upstream
  # sed-edits its colors.ini and restarts polybar; here the bar's config is in
  # the store, so the pick is written to the palette file the launcher reads,
  # and the unit is restarted. --no-block because this script runs inside that
  # unit: the restart would otherwise kill it before the job is queued.
  colorsScript = lib.getExe (pkgs.writeShellApplication {
    name = "polybar-docky-colors";
    runtimeInputs = [pkgs.coreutils pkgs.gnused pkgs.systemd pkgs.pywal16 pkgs.libnotify config.home.profileDirectory];
    bashOptions = [];
    text = ''
      ${loadPalette}

      declare -A accent=(${concatMapStringsSep " " (a: "[${elemAt a 0}]='${elemAt a 1}'") accents})
      declare -A dark_text=(${concatMapStringsSep " " (a: "[${elemAt a 0}]=${boolToString (elemAt a 2)}") accents})
      names=(${concatMapStringsSep " " (a: elemAt a 0) accents})

      # text colour for an accent by perceived brightness, as upstream does
      text_on() {
          local hex=''${1#\#}
          local r=$((16#''${hex:0:2})) g=$((16#''${hex:2:2})) b=$((16#''${hex:4:2}))
          if [ $((r * 299 + g * 587 + b * 114)) -gt 186000 ]; then
              echo "$2"
          else
              echo "$3"
          fi
      }

      random_color() {
          printf '#%06X' $(((RANDOM << 15 | RANDOM) & 0xFFFFFF))
      }

      save() {
          mkdir -p "$(dirname "${paletteFile}")"
          printf 'BG=%s\nFG=%s\nFGA=%s\nAC=%s\nMF=%s\nSC=%s\nAL=%s\n' \
              "$BG" "$FG" "$FGA" "$AC" "$MF" "$SC" "$AL" >"${paletteFile}.tmp"
          mv "${paletteFile}.tmp" "${paletteFile}"
          systemctl --user --no-block restart polybar-docky.service
      }

      # the scheme the colour picker writes: dark or light base + one accent
      scheme() {
          if [ "$1" = dark ]; then
              BG='#1F1F1F' FG='#FFFFFF' FGA='#8F8F8F' text='#1F1F1F'
          else
              BG='#FFFFFF' FG='#2E2E2E' FGA='#656565' text='#2E2E2E'
          fi
          AC=''${accent[$2]} SC='#E53935' AL='#7cb342'
          if [ "''${dark_text[$2]}" = true ]; then MF=$text; else MF='#FFFFFF'; fi
      }

      # pywal16 only generates the palette here: no wallpaper, terminal or
      # tty changes, which upstream's `wal -i` would also make.
      from_wallpaper() {
          img=$(sed -n "s/.*'\(.*\)'.*/\1/p" "$HOME/.fehbg" 2>/dev/null | tail -1)
          if [ ! -r "$img" ] || ! wal -n -s -t -e -q -i "$img"; then
              notify-send "Docky colours" "Could not read the current wallpaper"
              exit 1
          fi
          wal_color() { sed -n "s/^$1='\(#[0-9A-Fa-f]\{6\}\)'.*/\1/p" "$HOME/.cache/wal/colors.sh"; }
          BG=$(wal_color background) FG=$(wal_color foreground) FGA=$(wal_color color8)
          AC=$(wal_color color1) SC=$(wal_color color2) AL=$(wal_color color3)
          MF=$(text_on "$AC" '#202020' '#F5F5F5')
      }

      # random accents on upstream's dark base
      randomize() {
          BG='#1F1F1F' FG='#FFFFFF'
          FGA=$(random_color) AC=$(random_color) SC=$(random_color) AL=$(random_color)
          MF=$(text_on "$AC" '#0a0a0a' '#F5F5F5')
      }

      menu() {
          printf '󰒝  random\n󰋩  wallpaper\n'
          for variant in light dark; do
              suffix=""
              [ "$variant" = dark ] && suffix="-dark"
              for n in "''${names[@]}"; do
                  printf '<span foreground="%s">󰝤</span>  %s%s\n' "''${accent[$n]}" "$n" "$suffix"
              done
          done
      }

      chosen=$(menu | rofi -dmenu -i -markup-rows -p "󰏘" \
          -theme ${rofiDir}/menu.rasi -theme-str "$rofi_colors")
      [ -n "$chosen" ] || exit 0
      choice=''${chosen##* }

      case "$choice" in
          random) randomize ;;
          wallpaper) from_wallpaper ;;
          *-dark) [ -n "''${accent[''${choice%-dark}]:-}" ] || exit 0; scheme dark "''${choice%-dark}" ;;
          *) [ -n "''${accent[$choice]:-}" ] || exit 0; scheme light "$choice" ;;
      esac
      save
    '';
  });

  # The bar's environment carries the palette: polybar's config reads it as
  # ${env:DOCKY_*}, the module scripts as POLYBAR_* (see scriptPalette in
  # polybar.nix), and every rofi the bar opens as ROFI_* (dotfiles/rofi).
  startScript = lib.getExe (pkgs.writeShellApplication {
    name = "polybar-docky-start";
    runtimeInputs = [polybarPkg pkgs.i3 pkgs.coreutils pkgs.gnugrep];
    bashOptions = [];
    text = ''
      ${loadPalette}
      export DOCKY_BG=$BG DOCKY_FG=$FG DOCKY_FGA=$FGA DOCKY_AC=$AC DOCKY_MF=$MF DOCKY_SC=$SC DOCKY_AL=$AL
      export POLYBAR_ICON=$FG POLYBAR_ALERT=$SC POLYBAR_GOOD=$AL POLYBAR_DIM=$FGA
      export ROFI_BG=$BG ROFI_BG_ALT=''${AC}33 ROFI_FG=$FG ROFI_PRIMARY=$AC ROFI_SECONDARY=$AL \
          ROFI_ALERT=$SC ROFI_DISABLED=$FGA ROFI_ON_PRIMARY=$MF ROFI_RADIUS=0px \
          ROFI_POPUP_CORNER=southeast ROFI_POPUP_SIDE=south ROFI_POPUP_Y=-${toString popupY}px

      i3-msg -q "gaps bottom all set ${toString gap}"

      # one bar per monitor, the systray on the primary's, as in polybar.nix
      monitors=$(polybar --list-monitors)
      primary=$(printf '%s\n' "$monitors" | grep primary | head -1 | cut -d: -f1)
      if [ -z "$primary" ]; then
          primary=$(printf '%s\n' "$monitors" | head -1 | cut -d: -f1)
      fi

      printf '%s\n' "$monitors" | cut -d: -f1 | while read -r m; do
          bar=docky-aux
          [ "$m" = "$primary" ] && bar=docky
          MONITOR=$m polybar --reload -c "${config.xdg.configHome}/polybar/docky.ini" "$bar" &
      done
    '';
  });

  swapScript = pkgs.writeShellApplication {
    name = "polybar-docky";
    runtimeInputs = [pkgs.systemd];
    bashOptions = [];
    text = ''
      case "''${1:-toggle}" in
          on) systemctl --user start polybar-docky.service ;;
          off) systemctl --user start polybar.service ;;
          toggle)
              if systemctl --user -q is-active polybar-docky.service; then
                  systemctl --user start polybar.service
              else
                  systemctl --user start polybar-docky.service
              fi
              ;;
          colors) exec ${colorsScript} ;;
          *)
              echo "usage: polybar-docky [on|off|toggle|colors]" >&2
              exit 1
              ;;
      esac
    '';
  };

  modulesRight = concatStringsSep " " (
    ["color-switch" "wallpaper"]
    ++ optional cfg.marketplace "marketplace"
    ++ optional cfg.dnd "dnd"
    ++ ["volume"]
    ++ optional cfg.backlight "backlight"
    ++ optional cfg.battery "battery"
    ++ ["filesystem" "memory" "cpu"]
    ++ optional cfg.gpu "gpu"
    ++ ["bluetooth" "failed-units"]
    ++ optional cfg.lhc "lhc"
    ++ ["wlan" "eth"]
    ++ optional cfg.vpn "vpn"
    ++ ["xkeyboard"]
  );

  # accent-filled block at either end of the bar, as upstream
  block = {
    type = "custom/text";
    format-background = "\${color.primary}";
    format-foreground = "\${color.module-fg}";
    format-padding = 2;
  };

  settings = {
    color = {
      background = "\${env:DOCKY_BG:#1F1F1F}";
      foreground = "\${env:DOCKY_FG:#FFFFFF}";
      foreground-alt = "\${env:DOCKY_FGA:#8F8F8F}";
      module-fg = "\${env:DOCKY_MF:#FFFFFF}";
      primary = "\${env:DOCKY_AC:#e53935}";
      secondary = "\${env:DOCKY_SC:#E53935}";
      alternate = "\${env:DOCKY_AL:#7cb342}";
    };

    "bar/docky" = {
      monitor = "\${env:MONITOR:}";
      bottom = true;
      fixed-center = true;
      width = "98%";
      height = barHeight;
      offset-x = "1%";
      offset-y = offset;
      override-redirect = true;
      wm-restack = "i3";
      background = "\${color.background}";
      foreground = "\${color.foreground}";
      line-size = 2;
      line-color = "\${color.primary}";
      border-bottom-size = border;
      border-bottom-color = "\${color.primary}";
      padding = 0;
      module-margin-left = 1;
      module-margin-right = 1;
      font-0 = "JetBrainsMonoNerdFont:size=11;2";
      modules-left = "launcher xworkspaces";
      modules-center = "xwindow";
      modules-right = "${modulesRight} systray date sysmenu";
      cursor-click = "pointer";
      cursor-scroll = "ns-resize";
      enable-ipc = true;
    };

    # only one bar may own the tray
    "bar/docky-aux" = {
      "inherit" = "bar/docky";
      modules-right = "${modulesRight} date sysmenu";
    };

    "module/launcher" =
      block
      // {
        format = "󰀻";
        click-left = launcherScript;
        click-right = colorsScript;
      };

    "module/sysmenu" =
      block
      // {
        format = "󰐥";
        click-left = powermenuScript;
      };

    "module/color-switch" = {
      type = "custom/text";
      format = "󰏘";
      click-left = colorsScript;
    };

    # i3 only lists workspaces that exist, so upstream's "occupied" colour
    # goes to every unfocused one
    "module/xworkspaces" = {
      type = "internal/i3";
      strip-wsnumbers = true;
      pin-workspaces = true;
      label-focused = "%name%";
      label-focused-foreground = "\${color.primary}";
      label-focused-overline = "\${color.primary}";
      label-focused-padding = 1;
      label-unfocused = "%name%";
      label-unfocused-foreground = "\${color.alternate}";
      label-unfocused-padding = 1;
      label-visible = "%name%";
      label-visible-padding = 1;
      label-urgent = "%name%";
      label-urgent-foreground = "\${color.secondary}";
      label-urgent-padding = 1;
    };

    "module/xwindow" = {
      type = "internal/xwindow";
      label = "󰖯 %title%";
      label-maxlen = 40;
      label-empty = "";
    };

    "module/volume" = {
      type = "internal/pulseaudio";
      use-ui-max = false;
      interval = 5;
      format-volume = "<ramp-volume> <label-volume>";
      label-volume = "%percentage%%";
      ramp-volume-0 = "󰕿";
      ramp-volume-1 = "󰖀";
      ramp-volume-2 = "󰕾";
      format-muted = "<label-muted>";
      label-muted = "󰝟 Muted";
      label-muted-foreground = "\${color.foreground-alt}";
      click-right = main."module/volume".click-right;
    };

    "module/backlight" = {
      type = "internal/backlight";
      enable-scroll = true;
      format = "<ramp> <label>";
      label = "%percentage%%";
      ramp-0 = "󰃜";
      ramp-1 = "󰃝";
      ramp-2 = "󰃞";
      ramp-3 = "󰃟";
      ramp-4 = "󰃠";
    };

    "module/filesystem" = {
      type = "internal/fs";
      interval = 30;
      mount-0 = "/";
      fixed-values = true;
      label-mounted = "󰋊 %free%";
      label-unmounted = "󰋊 %mountpoint%: not mounted";
      label-unmounted-foreground = "\${color.foreground-alt}";
    };

    "module/wallpaper" = {
      type = "custom/text";
      format = "󰋩";
      click-left = "random-wallpaper";
    };

    "module/lhc" = {
      type = "custom/text";
      format = "󰝨 LHC";
      inherit (main."module/lhc") click-left click-right;
    };

    # left-click toggles the date; right-click opens the calendar, through
    # the action tag the main bar's label carries
    "module/date" = {
      type = "internal/date";
      interval = 1;
      date = "󰥔 %H:%M";
      date-alt = "󰃭 %a, %d %b %Y";
      inherit (main."module/date") label;
    };

    "module/xkeyboard" = {
      type = "internal/xkeyboard";
      blacklist-0 = "num lock";
      blacklist-1 = "scroll lock";
      format = "<label-layout> <label-indicator>";
      label-layout = "󰌌 %layout%";
      label-indicator-on = "%name%";
      label-indicator-on-foreground = "\${color.primary}";
    };

    "module/systray" = {
      type = "internal/tray";
      tray-spacing = "8pt";
      tray-background = "\${color.background}";
    };

    settings = {
      screenchange-reload = true;
      pseudo-transparency = false;
    };
  };

  # The script modules print their colours from POLYBAR_*, so they are the
  # main bar's own definitions, click handlers and all.
  sharedModules = [
    "memory"
    "cpu"
    "gpu"
    "battery"
    "bluetooth"
    "failed-units"
    "marketplace"
    "vpn"
    "dnd"
    "wlan"
    "eth"
  ];
in {
  home.packages = [swapScript];

  xdg.configFile."polybar/docky.ini".text = generators.toINI {} (
    settings // genAttrs (map (m: "module/${m}") sharedModules) (name: main.${name})
  );

  systemd.user.services.polybar-docky = {
    Unit = {
      Description = "Polybar, Docky theme (swapped in by polybar-docky)";
      # starting either bar stops the other
      Conflicts = ["polybar.service"];
      PartOf = ["graphical-session.target"];
      After = ["graphical-session-pre.target"];
      X-Restart-Triggers = ["${config.xdg.configFile."polybar/docky.ini".source}"];
    };
    Service = {
      Type = "forking";
      ExecStart = startScript;
      ExecStopPost = "${pkgs.i3}/bin/i3-msg -q 'gaps bottom all set 0'";
      Restart = "on-failure";
      inherit (config.systemd.user.services.polybar.Service) Environment;
    };
  };
}
