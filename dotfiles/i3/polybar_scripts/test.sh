#!/usr/bin/env bash

TEMP_PATH=$(for i in /sys/class/hwmon/hwmon*/temp*_input; do echo "$(<$(dirname $i)/name): $(cat ${i%_*}_label 2>/dev/null || echo $(basename ${i%_*})) $(readlink -f $i)"; done | awk '/coretemp.+temp1/ {print $5}')
echo "$(cat ${TEMP_PATH})"
