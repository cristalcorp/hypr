#!/bin/sh
# Workspace 1 at startup: Firefox left, terminal right, terminal center.
# Centered master (D-011, new_status = "master"): 1st window -> left,
# 2nd -> right, last -> center. Each app waits for the previous window.
wait_for() {   # $1 = class, $2 = count on workspace 1 (timeout 30 s)
    i=0
    while [ "$(hyprctl -j clients | jq --arg c "$1" '[.[] | select(.class == $c and .workspace.id == 1)] | length')" -lt "$2" ] \
          && [ "$i" -lt 60 ]; do
        sleep 0.5; i=$((i + 1))
    done
}
hyprctl dispatch 'hl.dsp.exec_cmd("firefox", { workspace = "1 silent" })'
wait_for firefox 1
hyprctl dispatch 'hl.dsp.exec_cmd("kitty", { workspace = "1 silent" })'
wait_for kitty 1
hyprctl dispatch 'hl.dsp.exec_cmd("kitty", { workspace = "1 silent" })'
