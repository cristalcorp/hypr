#!/bin/sh
# Workspace 1 at startup: Firefox left, Brave right, terminal center.
# Layout lua:centre (D-011): 1st window -> center, then the side with fewer
# windows (left first). Each app waits for the previous window.
wait_for() {   # $1 = class, $2 = count on workspace 1 (timeout 30 s)
    i=0
    while [ "$(hyprctl -j clients | jq --arg c "$1" '[.[] | select(.class == $c and .workspace.id == 1)] | length')" -lt "$2" ] \
          && [ "$i" -lt 60 ]; do
        sleep 0.5; i=$((i + 1))
    done
}
hyprctl dispatch 'hl.dsp.exec_cmd("kitty", { workspace = "1 silent" })'
wait_for kitty 1
hyprctl dispatch 'hl.dsp.exec_cmd("firefox", { workspace = "1 silent" })'
wait_for firefox 1
hyprctl dispatch 'hl.dsp.focus({ window = "class:kitty" })'   # centre focused -> Brave goes to the emptier side (right)
hyprctl dispatch 'hl.dsp.exec_cmd("brave --ozone-platform=wayland --enable-features=UseOzonePlatform", { workspace = "1 silent" })'
