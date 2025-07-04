#!/usr/bin/env bash

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use 
polybar-msg cmd quit
# Otherwise you can use the nuclear option:
# killall -q polybar

# Launch bar1 and bar2
echo "---" | tee -a /tmp/polybar1.log
# CHANGE PATH LATER !11
polybar --config=/etc/nixos/dotfiles/i3/polybar.ini 2>&1 | tee -a /tmp/polybar1.log & disown
# polybar --config=$HOME/tempdotfiles/dotfiles/i3/polybar.ini 2>&1 | tee -a /tmp/polybar1.log & disown

echo "Bars launched..."
