#!/bin/sh
# Rotate dark-gray wallpapers with a slow fade (OLED care: even wear on gaps and top band).
DIR="${1:-$HOME/.config/hypr/wallpapers}"
INTERVAL="${2:-300}"                                  # seconds between changes
until awww query >/dev/null 2>&1; do sleep 1; done   # wait for awww-daemon
while true; do
    for img in $(ls "$DIR"/*.png | shuf); do
        awww img --transition-type fade --transition-duration 20 --transition-fps 30 "$img"
        sleep "$INTERVAL"
    done
done
