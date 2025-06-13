#!/usr/bin/env bash

volume=$(pamixer --get-volume)
if pamixer --get-mute | grep -q true; then
    echo "%{F#A54242}󰝟%{F-} ${volume}"
else
    echo "%{F#F0C674}󰕾%{F-} ${volume}"
fi
%{F#F0C674}󱛟%{F-} %free%
