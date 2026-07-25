{
  config,
  pkgs,
  lib,
  ...
}: let
  pythonEnv = pkgs.python3.withPackages (ps: [ps.msal]);
  runner = pkgs.writeShellScriptBin "marketplace-check" ''
    export PATH=${lib.makeBinPath [pkgs.dunst pkgs.xdg-utils]}:$PATH
    exec ${pythonEnv}/bin/python3 ${./check.py} "$@"
  '';
  stateDir = "${config.xdg.stateHome}/marketplace-notifications";
  tokenCache = "${stateDir}/token_cache.json";
  # Presence of this file means "leave me alone". A flag rather than just
  # stopping the timer, because the timer is pulled back in at every login.
  disabledFlag = "${stateDir}/disabled";

  # Right-click target for the polybar module.
  toggle = pkgs.writeShellScriptBin "marketplace-toggle" ''
    set -uo pipefail
    export PATH=${lib.makeBinPath [pkgs.systemd pkgs.coreutils pkgs.libnotify]}:$PATH

    flag="${disabledFlag}"
    mkdir -p "$(dirname "$flag")"

    case "''${1:-toggle}" in
    on) rm -f "$flag" ;;
    off) : >"$flag" ;;
    toggle)
      if [ -e "$flag" ]; then rm -f "$flag"; else : >"$flag"; fi
      ;;
    status)
      [ -e "$flag" ] && echo off || echo on
      exit 0
      ;;
    *)
      echo "usage: marketplace-toggle [on|off|toggle|status]" >&2
      exit 1
      ;;
    esac

    if [ -e "$flag" ]; then
      systemctl --user stop marketplace-notifications.timer 2>/dev/null || true
      notify-send -a marketplace -u low "Marketplace" "polling off"
    else
      systemctl --user start marketplace-notifications.timer 2>/dev/null || true
      notify-send -a marketplace -u low "Marketplace" "polling on"
    fi
  '';
in {
  # `marketplace-check` in PATH for manual runs and the one-time device-code login
  home.packages = [runner toggle];

  systemd.user.services.marketplace-notifications = {
    Unit = {
      Description = "Notify about new Outlook Marketplace topics";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "marketplace-check-timer" ''
        # switched off from the polybar module (right-click) or `marketplace-toggle off`
        if [ -e "${disabledFlag}" ]; then
          exit 0
        fi
        # first login (device flow) must be done interactively: run marketplace-check in a terminal
        if [ ! -f "${tokenCache}" ]; then
          echo "no token cache yet — run marketplace-check manually once"
          exit 0
        fi
        exec ${runner}/bin/marketplace-check
      '';
    };
  };

  systemd.user.timers.marketplace-notifications = {
    Unit.Description = "Poll Outlook Marketplace every 5 minutes";
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
      RandomizedDelaySec = "30s";
    };
    Install.WantedBy = ["timers.target"];
  };
}
