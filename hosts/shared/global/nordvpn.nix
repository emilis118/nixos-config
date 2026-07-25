{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.nordvpn;
  iface = "nordlynx";
  unit = "wg-quick-${iface}.service";

  # `vpn up | down | toggle | status` — thin wrapper over the wg-quick unit so
  # connecting doesn't mean remembering the unit name.
  # polybar watches this so the shield icon flips the moment you click it
  # instead of on its next poll
  polybarFlag = "/tmp/polybar_vpn_state";

  vpnCtl = pkgs.writeShellScriptBin "vpn" ''
    set -euo pipefail
    export PATH=${makeBinPath [pkgs.systemd pkgs.wireguard-tools pkgs.curl pkgs.jq pkgs.coreutils]}:$PATH

    # no sudo: the polkit rule below lets wheel manage just this unit
    poke() { : >${polybarFlag} 2>/dev/null || true; }
    up() {
      systemctl start ${unit}
      poke
      status
    }
    down() {
      systemctl stop ${unit}
      poke
      echo "nordlynx down"
    }

    status() {
      if systemctl is-active --quiet ${unit}; then
        ip=$(curl -s --max-time 5 https://api.nordvpn.com/v1/helpers/ips/insights || true)
        if [ -n "$ip" ]; then
          echo "nordlynx up — $(echo "$ip" | jq -r '"\(.ip)  \(.city), \(.country)  protected=\(.protected)"')"
        else
          echo "nordlynx up (could not reach the Nord API to confirm)"
        fi
      else
        echo "nordlynx down"
      fi
    }

    case "''${1:-status}" in
    up | start | connect) up ;;
    down | stop | disconnect) down ;;
    toggle) systemctl is-active --quiet ${unit} && down || up ;;
    status) status ;;
    show) sudo wg show ${iface} ;;
    *)
      echo "usage: vpn [up|down|toggle|status|show]" >&2
      exit 1
      ;;
    esac
  '';

  # NordVPN rotates and retires servers, so pinning one in this file rots.
  # This asks Nord which server to use right now and prints the two lines to
  # paste into the host config.
  nordPick = pkgs.writeShellScriptBin "nordvpn-pick" ''
    set -euo pipefail
    export PATH=${makeBinPath [pkgs.curl pkgs.jq pkgs.coreutils]}:$PATH

    country="''${1:-}"
    url="https://api.nordvpn.com/v1/servers/recommendations?filters\[servers_technologies\]\[identifier\]=wireguard_udp&limit=1"
    if [ -n "$country" ]; then
      id=$(curl -s "https://api.nordvpn.com/v1/servers/countries" |
        jq -r --arg c "$country" '.[] | select((.name|ascii_downcase)==($c|ascii_downcase) or (.code|ascii_downcase)==($c|ascii_downcase)) | .id' | head -1)
      [ -n "$id" ] || { echo "unknown country: $country" >&2; exit 1; }
      url="$url&filters\[country_id\]=$id"
    fi

    curl -s "$url" | jq -r '.[0] |
      "# " + .hostname + "  (" + .locations[0].country.name + ", load " + (.load|tostring) + "%)",
      "nordvpn.endpoint = \"" + .station + ":51820\";",
      "nordvpn.publicKey = \"" + (.technologies[] | select(.identifier=="wireguard_udp") | .metadata[] | select(.name=="public_key") | .value) + "\";"'
  '';

  # rofi front-end: polybar right-click, and a launcher entry so it is
  # reachable from mod+d as well.
  vpnMenu = pkgs.writeShellScriptBin "vpn-menu" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.systemd pkgs.coreutils pkgs.libnotify]}:/run/current-system/sw/bin:$PATH

    if systemctl is-active --quiet ${unit}; then
      state="connected"
      action="Disconnect"
    else
      state="disconnected"
      action="Connect"
    fi

    choice=$(printf '%s\n' "$action" "Status" "Pick a server" |
      rofi -dmenu -i -p "vpn ($state)") || exit 0

    case "$choice" in
    Connect) ${vpnCtl}/bin/vpn up ;;
    Disconnect) ${vpnCtl}/bin/vpn down ;;
    Status) notify-send -a vpn "NordVPN" "$(${vpnCtl}/bin/vpn status)" ;;
    "Pick a server")
      country=$(rofi -dmenu -p "country (blank = fastest)" </dev/null) || exit 0
      out=$(${nordPick}/bin/nordvpn-pick $country 2>&1) || {
        notify-send -a vpn -u critical "NordVPN" "$out"
        exit 1
      }
      # the endpoint has to go into the host config and be rebuilt, so hand
      # it over rather than pretending it applied
      printf '%s' "$out" | ${pkgs.xclip}/bin/xclip -selection clipboard
      notify-send -a vpn "NordVPN — copied to clipboard" "$out

    Paste into the host's configuration.nix and rebuild."
      ;;
    esac
  '';
in {
  # NordVPN over plain WireGuard (what Nord calls NordLynx). No Nord client,
  # no proprietary daemon: just wg-quick with your account's NordLynx private
  # key, which comes out of sops.
  #
  # Inert until a host sets `nordvpn.enable = true`. See SOPS-SETUP.md for
  # getting the private key and picking a server.
  options.nordvpn = {
    enable = mkEnableOption "NordVPN over WireGuard (NordLynx)";

    autoStart = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Bring the tunnel up at boot. Off by default so a rebuild can never
        leave a machine without working networking — use `vpn up` instead.
      '';
    };

    endpoint = mkOption {
      type = types.str;
      example = "185.216.34.114:51820";
      description = "Server IP:port. Get a current one with `nordvpn-pick`.";
    };

    publicKey = mkOption {
      type = types.str;
      example = "zjIGh0Q1eIiVBFYpFyZFsWBWL7QcMZfRnA6nkQmLBnI=";
      description = "That server's WireGuard public key, also from `nordvpn-pick`.";
    };

    address = mkOption {
      type = types.listOf types.str;
      default = ["10.5.0.2/16"];
      description = "Tunnel address. NordLynx hands every client the same one.";
    };

    mtu = mkOption {
      type = types.int;
      default = 1420;
      description = "What NordLynx uses; lower it if large packets stall.";
    };

    dns = mkOption {
      type = types.listOf types.str;
      default = ["103.86.96.100" "103.86.99.100"];
      description = ''
        Resolvers to use while connected — Nord's own, so DNS doesn't leak to
        your ISP. On a host running blocky (networking.nameservers =
        127.0.0.1) set this to [] to keep resolving through blocky instead.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.secrets.enable;
        message = "nordvpn.enable needs secrets.enable: the NordLynx private key is read from sops.";
      }
      {
        assertion = cfg.endpoint != "" && cfg.publicKey != "";
        message = "nordvpn.enable needs nordvpn.endpoint and nordvpn.publicKey — run `nordvpn-pick`.";
      }
    ];

    # `nordvpn/private_key` in secrets/common.yaml. wg-quick reads the file at
    # start, so the key never appears in the store or in /etc.
    sops.secrets."nordvpn/private_key" = {
      mode = "0400"; # root-only; wg-quick runs as root
    };

    networking.wg-quick.interfaces.${iface} = {
      inherit (cfg) address dns mtu;
      privateKeyFile = config.sops.secrets."nordvpn/private_key".path;
      autostart = cfg.autoStart;

      peers = [
        {
          inherit (cfg) publicKey;
          endpoint = cfg.endpoint;
          # full tunnel: all v4 and v6 traffic goes through Nord
          allowedIPs = ["0.0.0.0/0" "::/0"];
          persistentKeepalive = 25;
        }
      ];
    };

    # Let the desktop user flip the tunnel without a password prompt — a
    # polybar click can't answer one. Scoped to this single unit; everything
    # else still goes through the normal polkit rules.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "${unit}" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    environment.systemPackages = [pkgs.wireguard-tools vpnCtl nordPick vpnMenu];
  };
}
