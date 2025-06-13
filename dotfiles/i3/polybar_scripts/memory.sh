#!/usr/bin/env bash

STATE_FILE="/tmp/polybar_memory_monitor_toggle"

# Create state file if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "1" > "$STATE_FILE"
fi

TOGGLE="$1"

# Toggle the state if 'toggle' argument is passed
if [ "$TOGGLE" = "toggle" ]; then
    if grep -q "1" "$STATE_FILE"; then
        echo "2" > "$STATE_FILE"
    elif grep -q "2" "$STATE_FILE"; then
        echo "3" > "$STATE_FILE"
    else
        echo "1" > "$STATE_FILE"
    fi
    exit 0
fi

used=$(free | awk '/^Mem/ {printf("%.1f", $3/1024/1024)}')
total=$(free | awk '/^Mem/ { printf("%.1f", $2/1024/1024) }')

if grep -q "1" "$STATE_FILE"; then
    percentage=$(awk "BEGIN {printf \"%.0f\n\", $used/$total*100}")
    echo "%{F#F0C674}RAM%{F-} ${percentage} %"
    exit 0
elif grep -q "2" "$STATE_FILE"; then
    echo "%{F#F0C674}RAM%{F-} ${used}/${total} GB"
    exit 0
elif grep -q "3" "$STATE_FILE"; then
    percentage=$(awk "BEGIN {printf \"%.0f\n\", $used/$total*100}")
    echo "%{F#F0C674}RAM%{F-} ${percentage}% ${used}/${total} GB"
    exit 0
else
    echo "SOMETHING WRONG WITH RAM"
fi
