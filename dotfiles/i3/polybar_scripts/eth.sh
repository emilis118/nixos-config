#!/usr/bin/env bash

STATE_FILE="/tmp/polybar_eth_toggle"

# Create state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "1" > "$STATE_FILE"
fi

TOGGLE="$1"

# Toggle the state if 'toggle' argument is passed
if [ "$TOGGLE" = "toggle" ]; then
    if grep -q "1" "$STATE_FILE"; then
        echo "2" > "$STATE_FILE"
    else
        echo "1" > "$STATE_FILE"
    fi
    exit 0
fi

# Find the first wired interface that is up
for path in /sys/class/net/en* /sys/class/net/eth*; do
    [ -e "$path" ] || continue
    dev="${path##*/}"
    if [ "$(cat "$path/operstate")" = "up" ]; then
        if grep -q "2" "$STATE_FILE"; then
            ip4=$(ip -o -4 addr show dev "$dev" | awk '{print $4}' | cut -d/ -f1 | head -1)
            echo "%{F#F0C674}󰈁%{F-} ${ip4}"
        else
            echo "%{F#F0C674}󰈁%{F-}"
        fi
        exit 0
    fi
done

# No wired connection: show nothing
echo ""
