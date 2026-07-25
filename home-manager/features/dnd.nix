{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.dnd;

  # One flag file is the whole state: `dnd` writes it, polybar watches it with
  # inotify (same pattern as the cpu/bluetooth toggles), so the bar reacts
  # immediately instead of on the next poll.
  stateFile = "/tmp/dnd_state";

  dnd = pkgs.writeShellScriptBin "dnd" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.dunst pkgs.blocky pkgs.systemd pkgs.coreutils]}:$PATH

    state="${stateFile}"

    # Only some machines run blocky (see hosts/shared/optional/blocky.nix);
    # everywhere else the notification half still applies.
    blocky_call() {
      ${
      if cfg.siteBlocking
      then ''
        blocky blocking "$@" >/dev/null 2>&1 ||
          echo "dnd: no blocky on 127.0.0.1:4000 — site blocking unchanged" >&2
      ''
      else ":"
    }
    }

    on() {
      echo on >"$state"
      # 1. silence everything: dunst queues notifications instead of showing
      #    them, so nothing is lost — `dnd off` shows what arrived
      dunstctl set-paused true
      # 2. block the social group (blocky's other groups are always on)
      blocky_call enable
      # 3. stop the marketplace poller from popping up while focused
      systemctl --user stop marketplace-notifications.timer 2>/dev/null || true
      echo "do not disturb: on"
    }

    off() {
      echo off >"$state"
      dunstctl set-paused false
      # re-enable everything, then switch the social group back off
      blocky_call enable
      blocky_call disable --groups social
      # only restart the poller if this machine has it and it wasn't
      # turned off by hand (marketplace-toggle writes its own flag)
      if [ ! -e "$HOME/.local/state/marketplace-notifications/disabled" ]; then
        systemctl --user start marketplace-notifications.timer 2>/dev/null || true
      fi
      echo "do not disturb: off"
    }

    case "''${1:-toggle}" in
    on | enable) on ;;
    off | disable) off ;;
    toggle)
      if [ "$(cat "$state" 2>/dev/null)" = "on" ]; then off; else on; fi
      ;;
    status)
      if [ "$(cat "$state" 2>/dev/null)" = "on" ]; then echo on; else echo off; fi
      ;;
    *)
      echo "usage: dnd [on|off|toggle|status]" >&2
      exit 1
      ;;
    esac
  '';
in {
  # Do not disturb: one switch that silences notifications, blocks the social
  # group in blocky (where blocky runs) and pauses the marketplace poller.
  # Bound to mod+shift+n, clickable in polybar, and in the rofi launcher.
  options.dnd = {
    enable = mkEnableOption "do-not-disturb switch" // {default = true;};

    siteBlocking = mkOption {
      type = types.bool;
      default = osConfig.services.blocky.enable;
      description = ''
        Also switch blocky's `social` blocklist group while toggling. Follows
        whether the host runs blocky; on machines without it, `dnd` is just
        the notification half.
      '';
    };

    stateFile = mkOption {
      type = types.str;
      default = stateFile;
      readOnly = true;
      description = "Where the on/off flag lives; polybar watches this path.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [dnd];

    xdg.desktopEntries.dnd = {
      name = "Do not disturb (toggle)";
      exec = "dnd toggle";
      icon = "notification-disabled";
      categories = ["Utility"];
    };

    # Leaving DND on across a reboot is almost always a mistake — you notice
    # days later that you missed everything. Clear it at login.
    systemd.user.services.dnd-reset = {
      Unit = {
        Description = "Clear do-not-disturb at session start";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${dnd}/bin/dnd off";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };
}
