#!/bin/sh
# OLED care (D-006): step the active-border gradient angle instead of rotating it every frame.
# Continuous "borderangle" loop redrew every frame at 240 Hz, even on hidden workspaces (I-011).
STEP="${1:-45}"       # degrees per step
INTERVAL="${2:-30}"   # seconds between steps
a=0
while true; do
    a=$(( (a + STEP) % 360 ))
    # wrapped in a function: a bare hl.config() makes hyprctl dispatch log "expected a dispatcher" in configerrors
    hyprctl dispatch "function() hl.config({ general = { col = { active_border = { colors = { \"rgba(33ccffee)\", \"rgba(00ff99ee)\" }, angle = $a } } } }) end" >/dev/null 2>&1
    sleep "$INTERVAL"
done
