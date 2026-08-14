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

  # polybar watches this so the shield icon flips the moment you click it
  # instead of on its next poll
  polybarFlag = "/tmp/polybar_vpn_state";

  # Which server the tunnel actually uses, chosen at runtime rather than at
  # build time. wg-quick's generated config still carries the peer from
  # nordvpn.endpoint/publicKey below; if this file exists, postUp swaps the
  # peer over to it right after the interface comes up.
  #
  # Kept in /var/lib rather than $HOME so the same pick survives a reboot and
  # is visible to root at start-up. Written by `vpn` as your own user (the
  # directory is group-writable by wheel), read by root — which is why
  # nordlynx-apply refuses anything that isn't an IP:port and a WireGuard key.
  stateDir = "/var/lib/nordlynx";
  stateFile = "${stateDir}/current";

  # Root half of the switch. Runs from wg-quick's postUp, so picking a server
  # needs no sudo and no rebuild: `vpn` writes the file, restarts the unit
  # (the polkit rule below makes that password-less) and this applies it.
  nordApply = pkgs.writeShellScriptBin "nordlynx-apply" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.wireguard-tools pkgs.coreutils pkgs.gnused pkgs.gnugrep]}:$PATH

    state=${stateFile}
    # nothing picked yet: the peer baked into the config stands
    [ -r "$state" ] || exit 0

    field() { sed -n "s/^$1=//p" "$state" | head -1; }
    endpoint=$(field endpoint)
    pub=$(field publicKey)

    # This runs as root on a file a non-root user wrote, so nothing reaches
    # `wg set` before it looks exactly like an endpoint and a key. Validate
    # everything first — a half-applied peer swap would leave the tunnel with
    # no peer at all.
    printf '%s' "$endpoint" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}:[0-9]{1,5}$' || {
      echo "nordlynx-apply: not an IP:port, ignoring $state" >&2
      exit 1
    }
    printf '%s' "$pub" | grep -Eq '^[A-Za-z0-9+/]{43}=$' || {
      echo "nordlynx-apply: not a WireGuard public key, ignoring $state" >&2
      exit 1
    }

    # The peer's allowedIPs are 0.0.0.0/0 either way and the routes wg-quick
    # installed point at the device, not at a peer — so swapping the peer
    # keeps the routing table exactly as it was.
    for p in $(wg show ${iface} peers); do
      [ "$p" = "$pub" ] || wg set ${iface} peer "$p" remove
    done
    wg set ${iface} peer "$pub" \
      endpoint "$endpoint" \
      allowed-ips 0.0.0.0/0,::/0 \
      persistent-keepalive 25
  '';

  # Shared by `vpn`, `vpn-menu` and `nordvpn-pick`: Nord's public API, the
  # country/city cache behind the menus, and reading/writing the pick.
  apiLib = ''
    api="https://api.nordvpn.com/v1"
    wgFilter='filters%5Bservers_technologies%5D%5Bidentifier%5D=wireguard_udp'

    state=${stateFile}
    cache="''${XDG_CACHE_HOME:-$HOME/.cache}/nordlynx"
    countries="$cache/countries.json"

    state_field() {
      [ -r "$state" ] || return 0
      sed -n "s/^$1=//p" "$state" | head -1
    }

    # What the tunnel is pointed at, for prompts and notifications.
    current_label() {
      local h c
      h=$(state_field hostname)
      c=$(state_field country)
      if [ -n "$h" ]; then
        echo "$h''${c:+ ($c)}"
      else
        echo "${cfg.endpoint} (built-in default)"
      fi
    }

    fetch_countries() {
      mkdir -p "$cache"
      curl -sf --max-time 15 "$api/servers/countries" -o "$countries.new" &&
        mv "$countries.new" "$countries"
    }

    # The country/city list is ~50 kB and changes about never, so cache it:
    # the menus open instantly and still work with no network.
    have_countries() {
      if [ ! -s "$countries" ] || [ -n "$(find "$countries" -mtime +14 2>/dev/null)" ]; then
        fetch_countries || true
      fi
      [ -s "$countries" ]
    }

    # One server per line, tab separated:
    #   hostname  ip  load  country  code  city  publicKey
    # $1 is an extra API filter (empty = fastest anywhere), $2 how many.
    server_query() {
      curl -sf --max-time 15 "$api/servers/recommendations?$wgFilter&limit=''${2:-1}''${1:-}" |
        jq -r '.[] | [
          .hostname,
          .station,
          (.load|tostring),
          .locations[0].country.name,
          .locations[0].country.code,
          (.locations[0].country.city.name // "-"),
          ([.technologies[] | select(.identifier=="wireguard_udp") | .metadata[] | select(.name=="public_key") | .value][0])
        ] | @tsv'
    }

    # A country ("France", "fr"), a city ("Paris"), or a server ("fr1178").
    # Empty means "fastest anywhere". Prints server_query lines.
    resolve() {
      local t="''${1:-}" n="''${2:-1}" id code

      [ -n "$t" ] || {
        server_query "" "$n"
        return
      }

      have_countries || {
        echo "can't reach the Nord API to look up '$t'" >&2
        return 1
      }

      # Nord calls the UK "GB", its servers are called uk1234
      [ "$(printf '%s' "$t" | tr 'A-Z' 'a-z')" = "uk" ] && t=gb

      id=$(jq -r --arg t "$t" '.[] | select((.name|ascii_downcase)==($t|ascii_downcase) or (.code|ascii_downcase)==($t|ascii_downcase)) | .id' "$countries" | head -1)
      if [ -n "$id" ]; then
        server_query "&filters%5Bcountry_id%5D=$id" "$n"
        return
      fi

      id=$(jq -r --arg t "$t" '.[].cities[] | select((.name|ascii_downcase)==($t|ascii_downcase) or (.dns_name|ascii_downcase)==($t|ascii_downcase)) | .id' "$countries" | head -1)
      if [ -n "$id" ]; then
        server_query "&filters%5Bcountry_city_id%5D=$id" "$n"
        return
      fi

      # A hostname: fr1178, fr1178.nordvpn.com. The API's own hostname filter
      # is ignored server-side, so pull that country's list and match. Every
      # server has its own key, so the whole line has to come from the API —
      # you can't just point the old key at a new IP.
      case "$t" in
      [a-zA-Z][a-zA-Z][0-9]*)
        code=$(printf '%s' "$t" | cut -c1-2 | tr 'A-Z' 'a-z')
        [ "$code" = "uk" ] && code=gb
        id=$(jq -r --arg c "$code" '.[] | select((.code|ascii_downcase)==$c) | .id' "$countries" | head -1)
        if [ -n "$id" ]; then
          # no early exit: quitting on the first match would SIGPIPE the
          # feeding jq, and pipefail would read that as a failed lookup
          server_query "&filters%5Bcountry_id%5D=$id" 100 |
            awk -F'\t' -v h="''${t%%.*}" 'tolower($1) ~ "^"tolower(h)"\\." && !seen++ {print}'
          return
        fi
        ;;
      esac

      echo "no country, city or server called '$t'" >&2
      return 1
    }

    # Pin one server_query line as the pick. The rename is atomic, so a start
    # racing a switch reads one or the other, never half a file.
    save_server() {
      local host ip load country code city pub
      IFS=$'\t' read -r host ip load country code city pub || return 1
      [ -n "$pub" ] || return 1
      mkdir -p "$(dirname "$state")" 2>/dev/null || true
      umask 022
      {
        echo "hostname=$host"
        echo "endpoint=$ip:51820"
        echo "publicKey=$pub"
        echo "country=$country"
        echo "countryCode=$code"
        echo "city=$city"
        echo "load=$load"
        echo "picked=$(date -Is)"
      } >"$state.$$" && mv "$state.$$" "$state"
    }
  '';

  # `vpn up|down|toggle|switch|status|list|…` — the whole thing from a shell,
  # with the menu below as a front-end for the same commands.
  vpnCtl = pkgs.writeShellScriptBin "vpn" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.systemd pkgs.wireguard-tools pkgs.curl pkgs.jq pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.findutils]}:$PATH

    ${apiLib}

    # no sudo: the polkit rule below lets wheel manage just this unit
    poke() { : >${polybarFlag} 2>/dev/null || true; }
    active() { systemctl is-active --quiet ${unit}; }

    insights() { curl -s --max-time 6 "$api/helpers/ips/insights"; }

    # Whether traffic is really leaving through Nord. An interface that came
    # up proves nothing: a retired server takes the tunnel with it and
    # wg-quick still reports success.
    protected() { insights | jq -e '.protected == true' >/dev/null 2>&1; }

    # Picking a server means talking to the API, which goes through the
    # tunnel when one is up — and a broken tunnel is exactly when you want to
    # switch. So drop it first if nothing gets out.
    ensure_api() {
      curl -sf --max-time 6 -o /dev/null "$api/helpers/ips/insights" && return 0
      if active; then
        echo "no route to the Nord API through the tunnel — bringing it down first"
        systemctl stop ${unit}
        poke
      fi
      curl -sf --max-time 10 -o /dev/null "$api/helpers/ips/insights"
    }

    pick() { # $1 = target, empty for fastest
      local line
      ensure_api || {
        echo "can't reach the Nord API" >&2
        return 1
      }
      line=$(resolve "''${1:-}" 1) || return 1
      [ -n "$line" ] || {
        echo "no WireGuard server matches '$1'" >&2
        return 1
      }
      printf '%s\n' "$line" | save_server || {
        echo "couldn't write $state" >&2
        return 1
      }
      echo "picked $(current_label)"
    }

    start() {
      if active; then systemctl restart ${unit}; else systemctl start ${unit}; fi
      poke
    }

    # A pinned server that Nord has since retired is the usual failure, and
    # it's a silent one. Rather than leave you to notice, take the same
    # country and pick a live server in it. Once only — if that doesn't work
    # either, the problem isn't the server.
    heal() {
      local where
      where=$(state_field country)
      echo "no traffic through $(current_label) — picking another server''${where:+ in $where}"
      systemctl stop ${unit}
      poke
      pick "$where" || pick "" || return 1
      start
      protected || echo "still nothing getting out — check the link, or try 'vpn up <country>'"
    }

    up() {
      if [ -n "''${1:-}" ]; then
        pick "$1" || return 1
        start
      else
        active || start
      fi
      protected || heal
      status
    }

    down() {
      systemctl stop ${unit}
      poke
      echo "nordlynx down"
    }

    status() {
      local j
      if active; then
        j=$(insights)
        if [ -n "$j" ]; then
          echo "nordlynx up — $(current_label) — $(echo "$j" | jq -r '"\(.ip)  \(.city // "?"), \(.country)  protected=\(.protected)"')"
        else
          echo "nordlynx up — $(current_label) (could not reach the Nord API to confirm)"
        fi
      else
        echo "nordlynx down — $(current_label) when started"
      fi
    }

    list() {
      local out
      out=$(resolve "''${1:-}" 25) || return 1
      [ -n "$out" ] || {
        echo "nothing found" >&2
        return 1
      }
      printf '%s\n' "$out" | awk -F'\t' '{printf "%-22s %-16s %-16s load %3s%%\n", $1, $4, $6, $3}'
    }

    case "''${1:-status}" in
    up | start | connect | switch) up "''${2:-}" ;;
    # `up` with no argument keeps the current pick, so re-picking the fastest
    # server anywhere needs a word of its own
    fastest)
      pick "" || exit 1
      start
      protected || heal
      status
      ;;
    down | stop | disconnect) down ;;
    toggle) active && down || up ;;
    reconnect)
      start
      protected || heal
      status
      ;;
    status) status ;;
    current) current_label ;;
    list | servers) list "''${2:-}" ;;
    countries)
      have_countries || exit 1
      jq -r '.[] | "\(.name) (\(.code))  \(.serverCount) servers"' "$countries" | sort
      ;;
    refresh)
      fetch_countries && echo "cached $(jq length "$countries") countries" || {
        echo "refresh failed" >&2
        exit 1
      }
      ;;
    default | reset)
      rm -f "$state"
      echo "back to the built-in default (${cfg.endpoint})"
      # only reconnect if there's a tunnel to move; being down is not a failure
      if active; then
        start
        protected || heal
        status
      fi
      ;;
    show) sudo wg show ${iface} ;;
    *)
      {
        echo "usage: vpn <command>"
        echo
        echo "  up|connect [where]  bring the tunnel up (optionally on a new server)"
        echo "  down                bring it down"
        echo "  toggle              flip it"
        echo "  reconnect           restart on the current server"
        echo "  switch <where>      pick a new server and connect"
        echo "  status              where you are, and whether Nord agrees you're covered"
        echo "  current             the server the tunnel points at"
        echo "  list [where]        servers with their load"
        echo "  countries           everywhere Nord has WireGuard servers"
        echo "  refresh             re-fetch the cached country list"
        echo "  default             forget the pick, go back to the one in the config"
        echo "  show                wg show (needs sudo)"
        echo
        echo "<where> is a country (\"France\", \"fr\"), a city (\"Paris\") or a server"
        echo "(\"fr1178\"). Switching takes effect immediately — no rebuild."
      } >&2
      exit 1
      ;;
    esac
  '';

  # Prints the two lines to paste into a host config, for pinning the
  # fallback server the tunnel starts on before anything else is picked.
  nordPick = pkgs.writeShellScriptBin "nordvpn-pick" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.curl pkgs.jq pkgs.coreutils pkgs.gawk pkgs.findutils]}:$PATH

    ${apiLib}

    line=$(resolve "''${1:-}" 1) || exit 1
    [ -n "$line" ] || {
      echo "no WireGuard server matches: ''${1:-}" >&2
      exit 1
    }
    IFS=$'\t' read -r host ip load country code city pub <<<"$line"
    echo "# $host  ($country, $city, load $load%)"
    echo "nordvpn.endpoint = \"$ip:51820\";"
    echo "nordvpn.publicKey = \"$pub\";"
  '';

  # rofi front-end: polybar right-click, and a launcher entry so it is
  # reachable from mod+d as well. Everything it does is a `vpn` command, so
  # the menu and the shell can't drift apart.
  vpnMenu = pkgs.writeShellScriptBin "vpn-menu" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.systemd pkgs.coreutils pkgs.curl pkgs.jq pkgs.gnused pkgs.gawk pkgs.findutils pkgs.libnotify]}:/run/current-system/sw/bin:$PATH

    ${apiLib}

    active() { systemctl is-active --quiet ${unit}; }
    note() { notify-send -a vpn "NordVPN" "$1"; }
    warn() { notify-send -a vpn -u critical "NordVPN" "$1"; }

    menu() { rofi -dmenu -i -p "$1" -mesg "$2"; }

    # Connecting can take a few seconds (API lookup, handshake, and a retry if
    # the server turned out to be dead), and rofi is already gone by then —
    # so say what's happening, then say how it went.
    connect_to() { # $1 = what to say we're doing, rest = vpn arguments
      local what=$1
      shift
      note "connecting''${what:+ — $what}…"
      out=$(${vpnCtl}/bin/vpn "$@" 2>&1)
      case "$out" in
      *"protected=true"*) note "$out" ;;
      *) warn "$out" ;;
      esac
    }

    if active; then
      header="connected · $(current_label)"
      toggle="󰦞  Disconnect"
    else
      header="disconnected · would use $(current_label)"
      toggle="󰦝  Connect"
    fi

    # every row is "<icon>  <label>", so the label is what's past the first
    # double space — favourites need no case of their own
    rows() {
      printf '%s\n' "$toggle"
      printf '%s\n' "󰑓  Reconnect"
      printf '%s\n' "󰓅  Fastest server anywhere"
      ${concatMapStringsSep "\n      " (c: "printf '%s\\n' ${escapeShellArg "󰈿  ${c}"}") cfg.favourites}
      printf '%s\n' "󰇧  Country…"
      printf '%s\n' "󰒋  Server in this country…"
      printf '%s\n' "󰋼  Status"
      printf '%s\n' "󰑐  Refresh server list"
      printf '%s\n' "󰜉  Back to the config default"
    }

    choice=$(rows | menu "vpn" "$header") || exit 0

    # every row is "<icon>  <label>"
    label=''${choice#*  }

    case "$label" in
    Disconnect)
      ${vpnCtl}/bin/vpn down >/dev/null
      note "disconnected"
      ;;

    Connect) connect_to "" up ;;

    Reconnect) connect_to "$(current_label)" reconnect ;;

    "Fastest server anywhere") connect_to "fastest anywhere" fastest ;;

    Status)
      note "$(${vpnCtl}/bin/vpn status)"
      ;;

    "Refresh server list")
      if fetch_countries; then
        note "cached $(jq length "$countries") countries"
      else
        warn "couldn't refresh the server list"
      fi
      ;;

    # `vpn default` reconnects by itself if the tunnel is up
    "Back to the config default") connect_to "the built-in default" default ;;

    "Country…")
      have_countries || {
        warn "no cached server list, and the API is unreachable"
        exit 1
      }
      pickC=$(jq -r '.[].name' "$countries" | sort |
        menu "country" "everywhere Nord has WireGuard servers") || exit 0
      [ -n "$pickC" ] || exit 0

      # a country picked — now how precise do you want to be about it
      sub=$({
        printf '󰓅  Fastest in %s\n' "$pickC"
        jq -r --arg c "$pickC" '.[] | select(.name==$c) | .cities[].name' "$countries" |
          sort | while IFS= read -r city; do
          [ -n "$city" ] && printf '󰇧  %s\n' "$city"
        done
        printf '%s\n' "󰒋  Pick a server…"
      } | menu "$pickC" "fastest in $pickC, a city, or one named server") || exit 0
      subLabel=''${sub#*  }

      case "$subLabel" in
      "Fastest in $pickC") connect_to "$pickC" up "$pickC" ;;
      "Pick a server…") exec ${vpnMenuServers}/bin/vpn-menu-servers "$pickC" ;;
      "") exit 0 ;;
      *) connect_to "$subLabel" up "$subLabel" ;;
      esac
      ;;

    "Server in this country…")
      here=$(state_field country)
      exec ${vpnMenuServers}/bin/vpn-menu-servers "$here"
      ;;

    # a favourite
    "") exit 0 ;;
    *) connect_to "$label" up "$label" ;;
    esac
  '';

  # The one list that has to come from the API live, because it carries each
  # server's load — split out so both ways into it are one exec away.
  vpnMenuServers = pkgs.writeShellScriptBin "vpn-menu-servers" ''
    set -uo pipefail
    export PATH=${makeBinPath [pkgs.systemd pkgs.coreutils pkgs.curl pkgs.jq pkgs.gnused pkgs.gawk pkgs.findutils pkgs.libnotify]}:/run/current-system/sw/bin:$PATH

    ${apiLib}

    note() { notify-send -a vpn "NordVPN" "$1"; }
    warn() { notify-send -a vpn -u critical "NordVPN" "$1"; }

    where="''${1:-}"
    list=$(resolve "$where" 25) || {
      warn "couldn't get a server list''${where:+ for $where}"
      exit 1
    }
    [ -n "$list" ] || {
      warn "no WireGuard servers''${where:+ in $where}"
      exit 1
    }

    pick=$(printf '%s\n' "$list" |
      awk -F'\t' '{printf "%-22s %-14s load %3s%%\n", $1, $6, $3}' |
      rofi -dmenu -i -p "server" -mesg "''${where:-fastest first} · lower load is better") || exit 0
    host=''${pick%% *}
    [ -n "$host" ] || exit 0

    # Straight from the list we already have: no second lookup, and the key
    # that belongs to this exact server comes with it.
    line=$(printf '%s\n' "$list" | awk -F'\t' -v h="$host" '$1==h && !seen++ {print}')
    [ -n "$line" ] || exit 0

    note "connecting — $host…"
    printf '%s\n' "$line" | save_server || {
      warn "couldn't write $state"
      exit 1
    }
    out=$(${vpnCtl}/bin/vpn reconnect 2>&1)
    case "$out" in
    *"protected=true"*) note "$out" ;;
    *) warn "$out" ;;
    esac
  '';
in {
  # NordVPN over plain WireGuard (what Nord calls NordLynx). No Nord client,
  # no proprietary daemon: just wg-quick with your account's NordLynx private
  # key, which comes out of sops.
  #
  # The server is picked at runtime (`vpn up <country>`, or the rofi menu) and
  # remembered in /var/lib/nordlynx — a rebuild is only needed to change the
  # fallback below. Nord retires servers constantly, which is why pinning one
  # in a config file rots.
  #
  # Inert until a host sets `nordvpn.enable = true`. See SOPS-SETUP.md for
  # getting the private key.
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

    # Only the starting point: whatever `vpn` last picked wins, and `vpn up`
    # replaces a dead server on its own. `nordvpn-pick` prints both lines if
    # you want to refresh the fallback anyway.
    endpoint = mkOption {
      type = types.str;
      # fr1178.nordvpn.com  (France, load 6% when picked, 2026-08-14)
      default = "187.13.202.87:51820";
      example = "185.216.34.114:51820";
      description = "Fallback server IP:port, used until something is picked at runtime.";
    };

    publicKey = mkOption {
      type = types.str;
      default = "VkrbtQHNdEeX8m71354tyzMvrkP14BNQM/aqiYpBbBk=";
      example = "zjIGh0Q1eIiVBFYpFyZFsWBWL7QcMZfRnA6nkQmLBnI=";
      description = "That server's WireGuard public key — every server has its own.";
    };

    favourites = mkOption {
      type = types.listOf types.str;
      default = ["France" "Switzerland" "Germany" "Netherlands" "United Kingdom" "United States" "Lithuania"];
      description = "Countries offered as one-click entries at the top of the rofi menu.";
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
    #
    # This is the *NordLynx* key, not the account access token — Nord's
    # dashboard only hands out the token, and wg-quick can't use it. The token
    # is kept alongside it as `nordvpn/access_token`; re-derive the key from it
    # (after a token regeneration, say) with:
    #
    #   sops -d --extract '["nordvpn"]["access_token"]' secrets/common.yaml |
    #     xargs -I{} curl -s -u token:{} \
    #       https://api.nordvpn.com/v1/users/services/credentials |
    #     jq -r .nordlynx_private_key
    #
    # then `sops set secrets/common.yaml '["nordvpn"]["private_key"]' '"<key>"'`.
    sops.secrets."nordvpn/private_key" = {
      mode = "0400"; # root-only; wg-quick runs as root
    };

    # Group-writable so `vpn` can save a pick without sudo. Everything root
    # then does with that file is validated in nordlynx-apply.
    systemd.tmpfiles.rules = ["d ${stateDir} 0775 root wheel -"];

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

      # Point the fresh interface at whatever was last picked. Never fatal:
      # a missing or unreadable pick just leaves the peer above in place,
      # which is still a working tunnel.
      postUp = "${nordApply}/bin/nordlynx-apply || true";
    };

    # Let the desktop user flip the tunnel without a password prompt — a
    # polybar click can't answer one. This is also what makes switching
    # servers rebuild-free: `vpn` writes the pick and restarts the unit.
    # Scoped to this single unit; everything else still goes through the
    # normal polkit rules.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "${unit}" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    environment.systemPackages = [pkgs.wireguard-tools vpnCtl nordPick vpnMenu vpnMenuServers nordApply];
  };
}
