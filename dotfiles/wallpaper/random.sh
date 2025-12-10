#!/bin/bash
shopt -s nullglob

wallpaper_dir="/etc/nixos/dotfiles/wallpaper"

files=("$wallpaper_dir"/*.jpg)
count=${#files[@]}

if (( count == 0 )); then
  echo "No JPG files found in $wallpaper_dir"
  exit 1
fi

# Set wallpaper using feh
feh --bg-scale "${files[RANDOM % count]}"
