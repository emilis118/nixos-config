#!/usr/bin/env bash

if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "no nvidia-smi"
    exit 0
fi

STATE_FILE="/tmp/polybar_gpu_monitor_toggle"

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

# If GPU info is turned off
if grep -q "off" "$STATE_FILE"; then
    LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)
    echo "%{F#F0C674}GPU%{F-} ${LOAD}%"
    exit 0
fi

# Get GPU stats using nvidia-smi
TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)
MEM_USED=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)
MEM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits)
LOAD=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

if [ "${TEMP}" -gt "70" ]; then
    echo "%{F#F0C674}GPU%{F-} ${LOAD}% %{F#A54242}${TEMP}%{F-}°C ${MEM_USED}/${MEM_TOTAL} MB"
    exit 0
fi

echo "%{F#F0C674}GPU%{F-} ${LOAD}% ${TEMP}°C ${MEM_USED}/${MEM_TOTAL} MB"
