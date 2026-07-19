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
  tokenCache = "${config.xdg.stateHome}/marketplace-notifications/token_cache.json";
in {
  # `marketplace-check` in PATH for manual runs and the one-time device-code login
  home.packages = [runner];

  systemd.user.services.marketplace-notifications = {
    Unit = {
      Description = "Notify about new Outlook Marketplace topics";
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "marketplace-check-timer" ''
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
