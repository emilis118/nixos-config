{
  pkgs,
  lib,
  osConfig,
  ...
}: let
  # Matches hosts/shared/global/nordvpn.nix. The polkit rule there lets wheel
  # start/stop exactly this unit without a password, which is what makes the
  # wrapper below work from a launcher click.
  iface = "nordlynx";
  unit = "wg-quick-${iface}.service";
  polybarFlag = "/tmp/polybar_vpn_state";

  # `runelite-vpn` — bring the tunnel up, launch the client, and kill it if the
  # tunnel goes away. Plain `runelite` (its own desktop entry, or the command)
  # still runs the client straight out with no VPN involvement.
  runeliteVpn = pkgs.writeShellScriptBin "runelite-vpn" ''
    set -uo pipefail
    export PATH=${lib.makeBinPath [pkgs.systemd pkgs.iproute2 pkgs.coreutils pkgs.libnotify pkgs.gnugrep pkgs.runelite]}:$PATH

    note() { notify-send -a runelite "RuneLite" "$1"; }
    warn() { notify-send -a runelite -u critical "RuneLite" "$1"; }
    # polybar's vpn module watches this file so the shield icon flips now
    # rather than on its next poll
    poke() { : >${polybarFlag} 2>/dev/null || true; }

    # Two conditions, because an active unit alone doesn't prove traffic is
    # leaving through the tunnel: the peer's allowedIPs are 0.0.0.0/0, so if
    # the default route isn't the nordlynx device we are not protected.
    tunnel_ok() {
      systemctl is-active --quiet ${unit} || return 1
      ip route get 1.1.1.1 2>/dev/null | grep -q "dev ${iface}" || return 1
    }

    started_it=0
    if ! tunnel_ok; then
      note "connecting to NordLynx…"
      if ! systemctl start ${unit}; then
        warn "could not start ${unit} — not launching"
        exit 1
      fi
      started_it=1
      poke

      # wg-quick returns once the interface and routes exist; give the route
      # table a moment to settle before believing it
      for _ in $(seq 30); do
        tunnel_ok && break
        sleep 0.5
      done

      if ! tunnel_ok; then
        warn "tunnel did not come up — not launching"
        [ "$started_it" = 1 ] && systemctl stop ${unit} && poke
        exit 1
      fi
    fi

    # `runelite` is the launcher: it updates/downloads the client, forks it
    # into its own JVM, and exits. So neither its PID nor a plain child wait
    # tracks "the game is running" — both go away seconds in, while the client
    # is still starting. A transient scope does track it: the forked client
    # inherits the cgroup, the scope stays active as long as anything is in
    # it, and stopping the scope takes launcher and client down together.
    # --scope (not a transient service) so it inherits DISPLAY and the rest of
    # this session's environment as-is.
    scope="runelite-vpn-$$"
    systemd-run --user --scope --quiet --collect --unit="$scope" -- runelite "$@" &
    starter=$!

    scope_active() { systemctl --user is-active --quiet "$scope.scope"; }

    # Wait for the scope to exist before watching it, but give up if the
    # launcher dies without ever getting one up.
    for _ in $(seq 60); do
      scope_active && break
      kill -0 "$starter" 2>/dev/null || break
      sleep 0.5
    done

    if ! scope_active; then
      warn "the client did not start"
      exit 1
    fi

    cleanup() {
      # Only undo what we did: if the tunnel was already up when we started,
      # leave it up.
      if [ "$started_it" = 1 ] && systemctl is-active --quiet ${unit}; then
        systemctl stop ${unit} && poke
      fi
    }
    trap cleanup EXIT

    # Kill switch. Polling rather than watching the unit over dbus keeps this
    # a shell script; 5s is the worst-case window where the client is up on
    # the bare connection. Loop ends on its own when you quit the game and the
    # last process leaves the scope.
    while scope_active; do
      if ! tunnel_ok; then
        warn "VPN dropped — killing the client"
        systemctl --user stop "$scope.scope" 2>/dev/null || true
        break
      fi
      sleep 5
    done
  '';

  vpnAvailable = osConfig.nordvpn.enable;
in {
  home.packages = [pkgs.runelite] ++ lib.optional vpnAvailable runeliteVpn;

  # The runelite package ships its own "RuneLite" entry, which stays the
  # no-VPN way in. This is the tunnelled one; i3 routes both to $ws4 by window
  # class (features/i3-profile.nix).
  xdg.desktopEntries.runelite-vpn = lib.mkIf vpnAvailable {
    name = "RuneLite (VPN)";
    exec = "runelite-vpn";
    icon = "runelite";
    categories = ["Game"];
  };
}
