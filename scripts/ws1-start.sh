#!/bin/sh
# Workspace 1 at startup: Firefox left, Brave right, terminal center.
# Layout lua:centre (D-014): 1st window -> center; a new window goes next to the focused side
# window, or to the side with fewer windows (left first) when the center is focused.
# Each app waits for the previous window.
wait_for() {   # $1 = class, $2 = count on workspace 1 (timeout 30 s)
    i=0
    while [ "$(hyprctl -j clients | jq --arg c "$1" '[.[] | select(.class == $c and .workspace.id == 1)] | length')" -lt "$2" ] \
          && [ "$i" -lt 60 ]; do
        sleep 0.5; i=$((i + 1))
    done
}
# address of the first window of class $1 on workspace 1
addr() { hyprctl -j clients | jq -r --arg c "$1" '[.[] | select(.class == $c and .workspace.id == 1)][0].address'; }
focus() { hyprctl dispatch "hl.dsp.focus({ window = \"address:$1\" })"; }

hyprctl dispatch 'hl.dsp.exec_cmd("kitty", { workspace = "1 silent" })'
wait_for kitty 1
K=$(addr kitty)
hyprctl dispatch 'hl.dsp.exec_cmd("firefox", { workspace = "1 silent" })'
wait_for firefox 1
focus "$K"            # ws 1 terminal, by address ("class:kitty" hit the ws 2 one, I-017)
hyprctl dispatch 'hl.dsp.exec_cmd("brave --ozone-platform=wayland --enable-features=UseOzonePlatform", { workspace = "1 silent" })'
wait_for brave-browser 1
# safety net: if Brave still landed left of the terminal, push it across the centre
B=$(addr brave-browser)
if [ "$(hyprctl -j clients | jq --arg b "$B" --arg k "$K" '([.[] | select(.address == $b)][0].at[0]) < ([.[] | select(.address == $k)][0].at[0])')" = true ]; then
    focus "$B"; hyprctl dispatch 'hl.dsp.layout("move r")'
fi
focus "$K"            # end on workspace 1, terminal focused
