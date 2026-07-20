#!/usr/bin/env bash
# Toggles holding the left mouse button down (instead of rapid-clicking).
set -u

PIDFILE="$HOME/.cache/autoclicker.pid"
HOLDFILE="$HOME/.cache/autoclicker-hold.state"

# If rapid-click mode is active, stop it first so we don't have two modes fighting.
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")"
    rm -f "$PIDFILE"
fi

if [[ -f "$HOLDFILE" ]]; then
    ydotool click 0x80   # left button up
    rm -f "$HOLDFILE"
    notify-send "Autoclicker" "Released"
else
    sleep 0.1
    ydotool click 0x40   # left button down
    touch "$HOLDFILE"
    notify-send "Autoclicker" "Holding left click"
fi
