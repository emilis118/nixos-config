#!/usr/bin/env bash

cpu_usage() {
  read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
  total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
  idle1=$((idle + iowait))

  sleep 1

  read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
  total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
  idle2=$((idle + iowait))

  total_diff=$((total2 - total1))
  idle_diff=$((idle2 - idle1))
  usage=$((100 * (total_diff - idle_diff) / total_diff))
  echo "$usage"
}


TEMP_PATH=$(for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done | awk '/coretemp.+temp1/ {print $5}')


STATE_FILE="/tmp/polybar_cpu_monitor_toggle"

# Create state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "off" > "$STATE_FILE"
fi

TOGGLE="$1"

# Toggle the state if 'toggle' argument is passed
if [ "$TOGGLE" = "toggle" ]; then
    if grep -q "on" "$STATE_FILE"; then
        echo "off" > "$STATE_FILE"
    else
        echo "on" > "$STATE_FILE"
    fi
    exit 0
fi

TEMP=$(awk '{print $1/1000}' ${TEMP_PATH})
LOAD=$(cpu_usage)

# If GPU info is turned off
if grep -q "off" "$STATE_FILE"; then
    echo "%{F#F0C674}CPU%{F-} ${LOAD}%"
    exit 0
fi

if [ "${TEMP}" -gt "80" ]; then
    echo "%{F#F0C674}CPU%{F-} ${LOAD}% %{F#A54242}${TEMP}%{F-}°C"
    exit 0
fi

echo "%{F#F0C674}CPU%{F-} ${LOAD}% ${TEMP}°C"
