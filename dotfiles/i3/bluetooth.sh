#!/bin/bash
# Check if bluetuith is already running
if ! pgrep -f "alacritty.*bluetuith" > /dev/null; then
    # Launch bluetuith in an alacritty terminal
    alacritty --class bluetuith -e bluetuith &
else
    # Focus the existing window
    i3-msg '[class="^bluetuith$"] focus'
fi

i3-msg workspace "8:Bluetooth"
