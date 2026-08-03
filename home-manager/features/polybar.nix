{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
with lib; let
  cfg = config.polybarModules;

  polybarPkg = pkgs.polybar.override {
    i3Support = true;
    pulseSupport = true;
  };

  yellow = "#F0C674";
  red = "#A54242";
  green = "#8C9440";
  dim = "#707880";

  # The toggle scripts run in polybar tail mode: they loop, re-rendering
  # every second (inotifywait timeout) and *immediately* when a click
  # handler touches the state file, so toggles react without polling lag.
  cpuScript = pkgs.writeShellScript "polybar-cpu" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.inotify-tools]}:$PATH

    STATE_FILE="/tmp/polybar_cpu_monitor_toggle"

    if [ ! -f "$STATE_FILE" ]; then
        echo "off" > "$STATE_FILE"
    fi

    if [ "$1" = "toggle" ]; then
        if grep -q "on" "$STATE_FILE"; then
            echo "off" > "$STATE_FILE"
        else
            echo "on" > "$STATE_FILE"
        fi
        exit 0
    fi

    # CPU package temperature; empty when no supported sensor is present.
    #
    # Probed by hwmon *driver name* rather than by device path, because the
    # path is vendor-specific and this file is shared by every host: Intel
    # exposes it as /sys/devices/platform/coretemp.N/... while AMD's k10temp
    # hangs off PCI (/sys/devices/pci0000:00/0000:00:18.3/...), so the old
    # coretemp glob matched nothing on amd-desktop. That did not just hide the
    # temperature — an empty TEMP takes the same render branch as "toggled
    # off", so the click handler silently stopped doing anything.
    #
    # temp1_input is the right input for both: "Package id 0" on coretemp,
    # "Tctl" on k10temp. Other hwmon devices (asus, nvme, ...) are skipped.
    TEMP_PATH=$(for h in /sys/class/hwmon/hwmon*; do
        case "$(cat "$h/name" 2>/dev/null)" in
            coretemp | k10temp)
                [ -e "$h/temp1_input" ] && echo "$h/temp1_input" && break
                ;;
        esac
    done)

    prev_total=0
    prev_idle=0
    usage=0

    # usage since the previous sample; keeps the last value when the
    # window is too short to be meaningful
    sample() {
        read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
        total=$((user + nice + system + idle + iowait + irq + softirq + steal))
        idl=$((idle + iowait))
        total_diff=$((total - prev_total))
        if [ "$prev_total" -gt 0 ] && [ "$total_diff" -gt 0 ]; then
            usage=$((100 * (total_diff - (idl - prev_idle)) / total_diff))
        fi
        prev_total=$total
        prev_idle=$idl
    }

    render() {
        TEMP=""
        [ -n "$TEMP_PATH" ] && TEMP=$(awk '{printf "%.0f", $1/1000}' "$TEMP_PATH" 2>/dev/null)

        if grep -q "off" "$STATE_FILE" || [ -z "$TEMP" ]; then
            echo "%{F${yellow}}CPU%{F-} ''${usage}%"
            return
        fi

        if [ "$TEMP" -gt "80" ]; then
            echo "%{F${yellow}}CPU%{F-} ''${usage}% %{F${red}}''${TEMP}%{F-}°C"
        else
            echo "%{F${yellow}}CPU%{F-} ''${usage}% ''${TEMP}°C"
        fi
    }

    sample
    sleep 0.3
    sample
    render

    while :; do
        if inotifywait -qq -t 1 -e close_write "$STATE_FILE" 2>/dev/null; then
            render # toggle clicked: redraw right away with cached usage
        else
            sample
            render
        fi
    done
  '';

  memoryScript = pkgs.writeShellScript "polybar-memory" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.procps pkgs.inotify-tools]}:$PATH

    STATE_FILE="/tmp/polybar_memory_monitor_toggle"

    if [ ! -f "$STATE_FILE" ]; then
        echo "1" > "$STATE_FILE"
    fi

    if [ "$1" = "toggle" ]; then
        if grep -q "1" "$STATE_FILE"; then
            echo "2" > "$STATE_FILE"
        elif grep -q "2" "$STATE_FILE"; then
            echo "3" > "$STATE_FILE"
        else
            echo "1" > "$STATE_FILE"
        fi
        exit 0
    fi

    render() {
        used=$(free | awk '/^Mem/ {printf("%.1f", $3/1024/1024)}')
        total=$(free | awk '/^Mem/ { printf("%.1f", $2/1024/1024) }')

        if grep -q "1" "$STATE_FILE"; then
            percentage=$(awk "BEGIN {printf \"%.0f\n\", $used/$total*100}")
            echo "%{F${yellow}}RAM%{F-} ''${percentage} %"
        elif grep -q "2" "$STATE_FILE"; then
            echo "%{F${yellow}}RAM%{F-} ''${used}/''${total} GB"
        elif grep -q "3" "$STATE_FILE"; then
            percentage=$(awk "BEGIN {printf \"%.0f\n\", $used/$total*100}")
            echo "%{F${yellow}}RAM%{F-} ''${percentage}% ''${used}/''${total} GB"
        else
            echo "SOMETHING WRONG WITH RAM"
        fi
    }

    render
    while :; do
        inotifywait -qq -t 1 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  # nvidia-smi comes from the system profile on hosts with the nvidia driver
  gpuScript = pkgs.writeShellScript "polybar-gpu" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.inotify-tools]}:/run/current-system/sw/bin:$PATH

    if ! command -v nvidia-smi >/dev/null 2>&1; then
        exit 0
    fi

    STATE_FILE="/tmp/polybar_gpu_monitor_toggle"

    if [ ! -f "$STATE_FILE" ]; then
        echo "off" > "$STATE_FILE"
    fi

    if [ "$1" = "toggle" ]; then
        if grep -q "on" "$STATE_FILE"; then
            echo "off" > "$STATE_FILE"
        else
            echo "on" > "$STATE_FILE"
        fi
        exit 0
    fi

    render() {
        if grep -q "off" "$STATE_FILE"; then
            LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
            echo "%{F${yellow}}GPU%{F-} ''${LOAD}%"
            return
        fi

        TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
        MEM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
        MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
        LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

        if [ "''${TEMP}" -gt "70" ]; then
            echo "%{F${yellow}}GPU%{F-} ''${LOAD}% %{F${red}}''${TEMP}%{F-}°C ''${MEM_USED}/''${MEM_TOTAL} MB"
        else
            echo "%{F${yellow}}GPU%{F-} ''${LOAD}% ''${TEMP}°C ''${MEM_USED}/''${MEM_TOTAL} MB"
        fi
    }

    render
    while :; do
        inotifywait -qq -t 1 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  # polybar's internal/battery can't swap labels on a click, and its
  # %consumption% only reaches the discharging label, so this reads sysfs
  # directly: power is reported while charging too, and left-click cycles
  # percentage -> + wattage -> + time (to empty, or to full while charging).
  batteryScript = pkgs.writeShellScript "polybar-battery" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gawk pkgs.inotify-tools]}:$PATH

    STATE_FILE="/tmp/polybar_battery_toggle"

    [ -f "$STATE_FILE" ] || echo "1" > "$STATE_FILE"

    if [ "$1" = "toggle" ]; then
        case "$(cat "$STATE_FILE")" in
            1) echo "2" > "$STATE_FILE" ;;
            2) echo "3" > "$STATE_FILE" ;;
            *) echo "1" > "$STATE_FILE" ;;
        esac
        exit 0
    fi

    BAT=$(for d in /sys/class/power_supply/BAT*; do
        [ -e "$d/capacity" ] && echo "$d" && break
    done)
    [ -n "$BAT" ] || exit 0

    # µW when the driver reports power, else µA × µV
    watts() {
        if [ -r "$BAT/power_now" ]; then
            awk '{w = $1 / 1000000; printf "%.1f", (w < 0 ? -w : w)}' "$BAT/power_now"
        elif [ -r "$BAT/current_now" ] && [ -r "$BAT/voltage_now" ]; then
            awk 'NR==1 {c = $1} NR==2 {v = $1}
                 END {w = c * v / 1000000000000; printf "%.1f", (w < 0 ? -w : w)}' \
                "$BAT/current_now" "$BAT/voltage_now"
        else
            echo "0.0"
        fi
    }

    # reservoir / rate in matching units: Wh over W, or Ah over A
    remaining() {
        if [ -r "$BAT/energy_now" ] && [ -r "$BAT/energy_full" ] && [ -r "$BAT/power_now" ]; then
            now=$(cat "$BAT/energy_now"); full=$(cat "$BAT/energy_full"); rate=$(cat "$BAT/power_now")
        elif [ -r "$BAT/charge_now" ] && [ -r "$BAT/charge_full" ] && [ -r "$BAT/current_now" ]; then
            now=$(cat "$BAT/charge_now"); full=$(cat "$BAT/charge_full"); rate=$(cat "$BAT/current_now")
        else
            return 1
        fi

        [ "$1" = "Charging" ] && now=$((full - now))

        awk -v n="$now" -v r="$rate" 'BEGIN {
            if (r < 0) r = -r
            if (r == 0 || n <= 0) exit 1
            m = int(n / r * 60 + 0.5)
            printf "%d:%02d", int(m / 60), m % 60
        }'
    }

    icon() {
        [ "$2" = "Charging" ] && { echo "󰂄"; return; }
        case $(( ($1 + 5) / 10 )) in
            0 | 1) echo "󰁺" ;;
            2) echo "󰁻" ;;
            3) echo "󰁼" ;;
            4) echo "󰁽" ;;
            5) echo "󰁾" ;;
            6) echo "󰁿" ;;
            7) echo "󰂀" ;;
            8) echo "󰂁" ;;
            9) echo "󰂂" ;;
            *) echo "󰁹" ;;
        esac
    }

    render() {
        cap=$(cat "$BAT/capacity")
        state=$(cat "$BAT/status")
        view=$(cat "$STATE_FILE")

        # "Not charging" is a plugged-in battery held at its charge limit
        if [ "$state" = "Full" ] || { [ "$cap" -ge 99 ] && [ "$state" != "Discharging" ]; }; then
            echo "%{F${yellow}}󰂄%{F-} Full"
            return
        fi

        ico=$(icon "$cap" "$state")
        if [ "$state" = "Discharging" ] && [ "$cap" -le 15 ]; then
            out="%{F${red}}''${ico} ''${cap}%%{F-}"
        else
            out="%{F${yellow}}''${ico}%{F-} ''${cap}%"
        fi

        [ "$view" = "1" ] || out="$out $(watts) W"
        if [ "$view" = "3" ]; then
            time_left=$(remaining "$state") && out="$out $time_left"
        fi

        echo "$out"
    }

    render
    while :; do
        inotifywait -qq -t 5 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  ethScript = pkgs.writeShellScript "polybar-eth" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.iproute2 pkgs.inotify-tools]}:$PATH

    STATE_FILE="/tmp/polybar_eth_toggle"

    if [ ! -f "$STATE_FILE" ]; then
        echo "1" > "$STATE_FILE"
    fi

    if [ "$1" = "toggle" ]; then
        if grep -q "1" "$STATE_FILE"; then
            echo "2" > "$STATE_FILE"
        else
            echo "1" > "$STATE_FILE"
        fi
        exit 0
    fi

    render() {
        # Find the first wired interface that is up
        for path in /sys/class/net/en* /sys/class/net/eth*; do
            [ -e "$path" ] || continue
            dev="''${path##*/}"
            if [ "$(cat "$path/operstate")" = "up" ]; then
                if grep -q "2" "$STATE_FILE"; then
                    ip4=$(ip -o -4 addr show dev "$dev" | awk '{print $4}' | cut -d/ -f1 | head -1)
                    echo "%{F${yellow}}󰈁%{F-} ''${ip4}"
                else
                    echo "%{F${yellow}}󰈁%{F-}"
                fi
                return
            fi
        done

        # No wired connection: show nothing
        echo ""
    }

    render
    while :; do
        inotifywait -qq -t 1 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  # Icon only by default, right-click reveals the network name — the eth
  # module's hidable IP, for wifi. A custom script rather than
  # internal/network because that one can't switch labels on a click.
  wlanScript = pkgs.writeShellScript "polybar-wlan" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.networkmanager pkgs.inotify-tools]}:$PATH

    STATE_FILE="/tmp/polybar_wlan_toggle"

    if [ ! -f "$STATE_FILE" ]; then
        echo "1" > "$STATE_FILE"
    fi

    if [ "$1" = "toggle" ]; then
        if grep -q "1" "$STATE_FILE"; then
            echo "2" > "$STATE_FILE"
        else
            echo "1" > "$STATE_FILE"
        fi
        exit 0
    fi

    render() {
        found=""
        for path in /sys/class/net/*/wireless; do
            [ -e "$path" ] || continue
            dev=$(basename "$(dirname "$path")")
            found=1
            if [ "$(cat "/sys/class/net/$dev/operstate")" = "up" ]; then
                if grep -q "2" "$STATE_FILE"; then
                    # only pay for nmcli when the name is on screen
                    ssid=$(nmcli -t -f GENERAL.CONNECTION device show "$dev" 2>/dev/null | cut -d: -f2-)
                    echo "%{F${yellow}}󰖩%{F-} ''${ssid}"
                else
                    echo "%{F${yellow}}󰖩%{F-}"
                fi
                return
            fi
        done

        # radio present but down: dimmed off icon. No radio at all: nothing
        if [ -n "$found" ]; then
            echo "%{F${dim}}󰖪%{F-}"
        else
            echo ""
        fi
    }

    render
    while :; do
        inotifywait -qq -t 1 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  bluetoothScript = pkgs.writeShellScript "polybar-bluetooth" ''
    export PATH=${makeBinPath [pkgs.bluez pkgs.coreutils pkgs.gnugrep pkgs.gnused pkgs.inotify-tools]}:$PATH

    # icon + battery by default; right-click toggles showing the device name
    STATE_FILE="/tmp/polybar_bluetooth_toggle"

    if [ ! -f "$STATE_FILE" ]; then
        echo "off" > "$STATE_FILE"
    fi

    if [ "$1" = "toggle" ]; then
        if grep -q "on" "$STATE_FILE"; then
            echo "off" > "$STATE_FILE"
        else
            echo "on" > "$STATE_FILE"
        fi
        exit 0
    fi

    render() {
    # No adapter or powered off: dimmed off icon
    if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        echo "%{F${dim}}󰂲%{F-}"
        return
    fi

    connected=$(bluetoothctl devices Connected 2>/dev/null)
    if [ -z "$connected" ]; then
        echo "%{F${dim}}󰂯%{F-}"
        return
    fi

    count=$(printf '%s\n' "$connected" | grep -c .)
    line=$(printf '%s\n' "$connected" | head -1)
    mac=$(printf '%s' "$line" | cut -d' ' -f2)
    name=$(printf '%s' "$line" | cut -d' ' -f3-)
    batt=$(bluetoothctl info "$mac" 2>/dev/null | sed -n 's/.*Battery Percentage.*(\([0-9]*\)).*/\1/p')

    out="%{F${yellow}}󰂱%{F-}"
    if grep -q "on" "$STATE_FILE"; then
        out="$out $name"
    fi
    if [ -n "$batt" ]; then
        if [ "$batt" -le 20 ]; then
            out="$out %{F${red}}$batt%%{F-}"
        else
            out="$out $batt%"
        fi
    fi
    [ "$count" -gt 1 ] && out="$out +$((count - 1))"
    echo "$out"
    }

    render
    while :; do
        inotifywait -qq -t 5 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  failedUnitsScript = pkgs.writeShellScript "polybar-failed-units" ''
    export PATH=${makeBinPath [pkgs.systemd pkgs.gnugrep]}:$PATH

    sys=$(systemctl --failed --no-legend --plain 2>/dev/null | grep -c .)
    usr=$(systemctl --user --failed --no-legend --plain 2>/dev/null | grep -c .)
    total=$((sys + usr))

    # Hidden while everything is healthy
    if [ "$total" -gt 0 ]; then
        echo "%{F${red}}󰀦 $total%{F-}"
    fi
  '';

  failedUnitsView = pkgs.writeShellScript "polybar-failed-units-view" ''
    exec ${pkgs.alacritty}/bin/alacritty --hold -e sh -c \
      'systemctl --failed; echo; systemctl --user --failed'
  '';

  # There is no public text API for LHC Page 1, only the vistar screenshots
  # refreshed about once a minute, so the module is a launcher: click fetches
  # the current Page 1 image, right-click opens the live vistar page.
  lhcView = pkgs.writeShellScript "polybar-lhc-view" ''
    export PATH=${makeBinPath [pkgs.curl pkgs.feh]}:$PATH
    curl -sf -m 10 -o /tmp/lhc1.png https://vistar-capture.s3.cern.ch/lhc1.png \
      && exec feh --title "LHC Page 1" /tmp/lhc1.png
  '';

  lhcWeb = pkgs.writeShellScript "polybar-lhc-web" ''
    export PATH=${config.home.profileDirectory}/bin:$PATH
    exec firefox "https://op-webtools.web.cern.ch/vistar/vistars.php?usr=LHC1"
  '';

  # adi1090x-style applet: one row of icon buttons popped out under the
  # click. Loops so volume/mute clicks keep the menu open; Escape or the
  # mixer button leave.
  volumeMenuScript = pkgs.writeShellScript "polybar-volume-menu" ''
    export PATH=${makeBinPath [pkgs.pamixer pkgs.xdotool pkgs.i3 pkgs.jq pkgs.coreutils]}:${config.home.profileDirectory}/bin:$PATH

    theme=${../../dotfiles/rofi/volume-applet.rasi}
    sel=2 # start on the mute button

    # Pin the window's top-right corner under the pointer: find the monitor
    # containing it and the pointer's offset from that monitor's right edge.
    # (rofi's own -m -3 "place at mouse" puts the window off-screen in 2.0.
    # Don't use xrandr here: any query, even --listactivemonitors, makes the
    # X server re-probe the outputs — 1-2s of the popup feeling stuck. i3
    # already knows the layout and answers over IPC in milliseconds.)
    eval "$(xdotool getmouselocation --shell)" # sets X and Y
    pos=$(i3-msg -t get_outputs | jq -r --argjson mx "$X" --argjson my "$Y" '
        first(.[] | select(.active
            and .rect.x <= $mx and $mx < .rect.x + .rect.width
            and .rect.y <= $my and $my < .rect.y + .rect.height))
        | "\(.name) \($mx - .rect.x - .rect.width)"')
    place=()
    [ -n "$pos" ] && place=(-m "''${pos% *}" -theme-str "window { x-offset: ''${pos#* }px; }")

    while :; do
        vol=$(pamixer --get-volume)
        urgent=()
        if [ "$(pamixer --get-mute)" = "true" ]; then
            mute_icon="󰝟"
            status="muted ($vol%)"
            urgent+=(1)
        else
            mute_icon="󰕾"
            status="volume $vol%"
        fi
        if [ "$(pamixer --default-source --get-mute)" = "true" ]; then
            mic_icon="󰍭"
            urgent+=(3)
        else
            mic_icon="󰍬"
        fi

        extra=()
        [ "''${#urgent[@]}" -gt 0 ] && extra=(-u "$(IFS=,; echo "''${urgent[*]}")")

        idx=$(printf '󰝞\n%s\n󰝝\n%s\n󰒓\n' "$mute_icon" "$mic_icon" | rofi -dmenu \
            -theme "$theme" -mesg "$status" -format i \
            -selected-row "$sel" "''${place[@]}" "''${extra[@]}" \
            -me-select-entry "" -me-accept-entry MousePrimary)

        case "$idx" in
            0) pamixer -d 5 ;;
            1) pamixer -t ;;
            2) pamixer -i 5 ;;
            3) pamixer --default-source -t ;;
            4) exec ${pkgs.pavucontrol}/bin/pavucontrol ;;
            *) exit 0 ;;
        esac
        sel=$idx
    done
  '';

  # NordLynx state. The unit lives on the system bus, so this polls; `vpn`
  # also touches the flag file on every up/down, which wakes the loop
  # immediately so a click doesn't feel laggy.
  vpnScript = pkgs.writeShellScript "polybar-vpn" ''
    export PATH=${makeBinPath [pkgs.systemd pkgs.coreutils pkgs.inotify-tools]}:$PATH

    STATE_FILE="/tmp/polybar_vpn_state"
    [ -f "$STATE_FILE" ] || : >"$STATE_FILE"

    render() {
        if systemctl is-active --quiet wg-quick-nordlynx.service; then
            echo "%{F${green}}󰦝%{F-}"
        else
            echo "%{F${dim}}󰦞%{F-}"
        fi
    }

    render
    while :; do
        inotifywait -qq -t 5 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  # Do not disturb. features/dnd.nix owns the switch; this just reflects and
  # toggles it.
  dndScript = pkgs.writeShellScript "polybar-dnd" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.inotify-tools]}:$PATH

    STATE_FILE="${config.dnd.stateFile}"
    [ -f "$STATE_FILE" ] || echo off >"$STATE_FILE"

    render() {
        if [ "$(cat "$STATE_FILE" 2>/dev/null)" = "on" ]; then
            echo "%{F${red}}󰂛%{F-}"
        else
            echo "%{F${dim}}󰂚%{F-}"
        fi
    }

    render
    while :; do
        inotifywait -qq -t 30 -e close_write "$STATE_FILE" 2>/dev/null
        render
    done
  '';

  # Left-click checks now, right-click turns the 5-minute poller off/on.
  marketplaceScript = pkgs.writeShellScript "polybar-marketplace" ''
    export PATH=${makeBinPath [pkgs.coreutils pkgs.inotify-tools]}:$PATH

    FLAG="${config.xdg.stateHome}/marketplace-notifications/disabled"
    mkdir -p "$(dirname "$FLAG")"

    render() {
        if [ -e "$FLAG" ]; then
            echo "%{F${dim}}󰄰%{F-}"
        else
            echo "%{F${yellow}}󰄐%{F-}"
        fi
    }

    render
    while :; do
        # watch the directory: the flag itself comes and goes, and
        # inotifywait can't watch a path that doesn't exist yet
        inotifywait -qq -t 30 -e create -e delete "$(dirname "$FLAG")" 2>/dev/null
        render
    done
  '';

  # rofi-power-menu is spawned by rofi from PATH, hence the export
  powermenuScript = pkgs.writeShellScript "polybar-powermenu" ''
    export PATH=${config.home.profileDirectory}/bin:$PATH
    exec rofi -show power
  '';

  modulesRight = concatStringsSep " " (
    ["wallpaper"]
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
    ++ ["powermenu"]
  );
in {
  options.polybarModules = {
    backlight = mkEnableOption "screen backlight module in polybar";
    battery = mkEnableOption "battery module in polybar";
    gpu = mkEnableOption "nvidia GPU module in polybar";
    lhc = mkEnableOption "LHC Page 1 module in polybar";
    marketplace = mkEnableOption "manual Outlook Marketplace check button in polybar";
    # follows the host: turning on nordvpn gets you the bar module and the
    # rofi entry without a second flag
    vpn = mkEnableOption "NordLynx status/toggle in polybar" // {default = osConfig.nordvpn.enable;};
    dnd = mkEnableOption "do-not-disturb toggle in polybar" // {default = config.dnd.enable;};
  };

  config = {
    services.polybar = {
      enable = true;
      package = polybarPkg;

      # One bar per monitor: the primary gets bar/main (with the systray),
      # the others get bar/aux. A monitor hotplug needs a service restart
      # (mod+shift+r restarts i3, whose startup restarts this unit).
      script = ''
        # Kill bars left over from a previous session or the pre-systemd setup
        polybar-msg cmd quit >/dev/null 2>&1 || true
        sleep 0.5

        monitors=$(polybar --list-monitors)
        primary=$(printf '%s\n' "$monitors" | grep primary | head -1 | cut -d: -f1)
        if [ -z "$primary" ]; then
          primary=$(printf '%s\n' "$monitors" | head -1 | cut -d: -f1)
        fi

        printf '%s\n' "$monitors" | cut -d: -f1 | while read -r m; do
          bar=aux
          [ "$m" = "$primary" ] && bar=main
          MONITOR=$m polybar --reload "$bar" &
        done
      '';

      settings = {
        colors = {
          background = "#282A2E";
          background-alt = "#373B41";
          foreground = "#C5C8C6";
          primary = yellow;
          secondary = "#8ABEB7";
          alert = red;
          disabled = dim;
        };

        "bar/main" = {
          monitor = "\${env:MONITOR:}";
          width = "100%";
          height = "24pt";
          radius = 4;
          background = "\${colors.background}";
          foreground = "\${colors.foreground}";
          line-size = "3pt";
          border-size = "0pt";
          border-color = "#00000000";
          padding-left = 0;
          padding-right = 1;
          module-margin = 1;
          separator = "|";
          separator-foreground = "\${colors.disabled}";
          font-0 = "JetBrainsMonoNerdFont:size=12";
          modules-left = "xworkspaces xwindow";
          modules-center = "date xkeyboard systray";
          modules-right = modulesRight;
          cursor-click = "pointer";
          cursor-scroll = "ns-resize";
          enable-ipc = true;
        };

        # Secondary monitors: same bar without the systray (only one bar
        # may own the tray).
        "bar/aux" = {
          "inherit" = "bar/main";
          modules-center = "date xkeyboard";
        };

        "module/xworkspaces" = {
          type = "internal/i3";
          strip-wsnumbers = true;
          # each monitor's bar only shows its own workspaces
          pin-workspaces = true;
          label-focused = "%name%";
          label-focused-background = "\${colors.background-alt}";
          label-focused-underline = "\${colors.primary}";
          label-focused-padding = 1;
          label-unfocused = "%name%";
          label-unfocused-padding = 1;
          label-visible = "%name%";
          label-visible-padding = 1;
          label-urgent = "%name%";
          label-urgent-background = "\${colors.alert}";
          label-urgent-padding = 1;
        };

        "module/xwindow" = {
          type = "internal/xwindow";
          label = "%title%";
          label-maxlen = 50;
        };

        "module/filesystem" = {
          type = "internal/fs";
          interval = 25;
          mount-0 = "/";
          label-mounted = "%{F${yellow}}󰋊%{F-} %free%";
          label-unmounted-foreground = "\${colors.disabled}";
        };

        # event-driven: mute/scroll feedback is instant, no polling
        "module/volume" = {
          type = "internal/pulseaudio";
          use-ui-max = false;
          interval = 5; # scroll step in percentage points
          format-volume = "<label-volume>";
          label-volume = "%{F${yellow}}󰕾%{F-} %percentage%";
          format-muted = "<label-muted>";
          label-muted = "%{F${red}}󰝟%{F-} %percentage%";
          click-right = "${volumeMenuScript}";
        };

        "module/memory" = {
          type = "custom/script";
          exec = "${memoryScript}";
          tail = true;
          click-left = "${memoryScript} toggle";
        };

        "module/cpu" = {
          type = "custom/script";
          exec = "${cpuScript}";
          tail = true;
          click-left = "${cpuScript} toggle";
        };

        "module/gpu" = {
          type = "custom/script";
          exec = "${gpuScript}";
          tail = true;
          click-left = "${gpuScript} toggle";
        };

        "module/wallpaper" = {
          type = "custom/script";
          exec = ''echo "%{F${yellow}}󰋩%{F-}"'';
          interval = 3600;
          click-left = "random-wallpaper";
        };

        "module/bluetooth" = {
          type = "custom/script";
          exec = "${bluetoothScript}";
          tail = true;
          click-left = "rofi-bluetooth";
          click-right = "${bluetoothScript} toggle";
        };

        "module/failed-units" = {
          type = "custom/script";
          exec = "${failedUnitsScript}";
          interval = 15;
          click-left = "${failedUnitsView}";
        };

        "module/lhc" = {
          type = "custom/script";
          exec = ''echo "%{F${yellow}}󰝨%{F-} LHC"'';
          interval = 3600;
          click-left = "${lhcView}";
          click-right = "${lhcWeb}";
        };

        # left-click runs the marketplace checker (from
        # features/marketplace-notifications); new topics arrive as
        # notifications, "No new topics" when there's nothing.
        # Right-click switches the 5-minute background poller off; the icon
        # dims while it is off and the setting survives a reboot.
        "module/marketplace" = {
          type = "custom/script";
          exec = "${marketplaceScript}";
          tail = true;
          click-left = "marketplace-check --notify-empty";
          click-right = "marketplace-toggle";
        };

        # left-click connects/disconnects, right-click opens the menu
        # (status, pick a country, ...)
        "module/vpn" = {
          type = "custom/script";
          exec = "${vpnScript}";
          tail = true;
          click-left = "vpn toggle";
          click-right = "vpn-menu";
        };

        "module/dnd" = {
          type = "custom/script";
          exec = "${dndScript}";
          tail = true;
          click-left = "dnd toggle";
        };

        "module/powermenu" = {
          type = "custom/script";
          exec = ''echo "%{F${yellow}}󰐥%{F-}"'';
          interval = 3600;
          click-left = "${powermenuScript}";
        };

        "module/date" = {
          type = "internal/date";
          interval = 1;
          date = "%H:%M";
          date-alt = "%Y-%m-%d %H:%M";
          label = "%date%";
          label-foreground = "\${colors.primary}";
        };

        "module/xkeyboard" = {
          type = "internal/xkeyboard";
          blacklist = ["num lock"];
          label-layout = "%layout%";
          label-layout-foreground = "\${colors.primary}";
          label-indicator-padding = 2;
          label-indicator-margin = 1;
          label-indicator-foreground = "\${colors.background}";
          label-indicator-background = "\${colors.secondary}";
        };

        "module/systray" = {
          type = "internal/tray";
          format-margin = "8pt";
          tray-spacing = "16pt";
        };

        # left-click opens the rofi network picker (networkmanager_dmenu),
        # right-click toggles showing the network name
        "module/wlan" = {
          type = "custom/script";
          exec = "${wlanScript}";
          tail = true;
          click-left = "networkmanager_dmenu";
          click-right = "${wlanScript} toggle";
        };

        "module/eth" = {
          # icon only; click toggles showing the local IP
          type = "custom/script";
          exec = "${ethScript}";
          tail = true;
          click-left = "${ethScript} toggle";
        };

        # laptop panel brightness; scroll on the module to change it
        "module/backlight" = {
          type = "internal/backlight";
          enable-scroll = true;
          format = "<label>";
          label = "%{F${yellow}}󰃞%{F-} %percentage%";
        };

        # click cycles percentage / + wattage / + time remaining
        "module/battery" = {
          type = "custom/script";
          exec = "${batteryScript}";
          tail = true;
          click-left = "${batteryScript} toggle";
        };

        settings = {
          screenchange-reload = true;
          pseudo-transparency = true;
        };
      };
    };

    # The generated unit's PATH only has polybar itself; click handlers
    # (random-wallpaper, rofi-bluetooth, networkmanager_dmenu, ...) and the
    # launch script need the user and system profiles too.
    systemd.user.services.polybar.Service.Environment = mkForce [
      "PATH=${polybarPkg}/bin:${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
    ];
  };
}
