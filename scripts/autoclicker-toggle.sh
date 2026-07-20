#!/usr/bin/env bash
# Toggles a background auto-clicker (left click, 10 clicks/sec) on/off.
set -u

PIDFILE="$HOME/.cache/autoclicker.pid"
HOLDFILE="$HOME/.cache/autoclicker-hold.state"
INTERVAL=0.1   # seconds between clicks -> 10 clicks/sec
BUTTON=0xC0    # left click (down+up)

# If hold-mode is active, release it first so we don't have two modes fighting.
if [[ -f "$HOLDFILE" ]]; then
    ydotool click 0x80   # left button up
    rm -f "$HOLDFILE"
fi

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    kill "$(cat "$PIDFILE")"
    rm -f "$PIDFILE"
    notify-send "Autoclicker" "Stopped"
else
    setsid bash -c "
        sleep 0.1
        while true; do
            ydotool click $BUTTON
            sleep $INTERVAL
        done
    " &>/dev/null &
    echo $! > "$PIDFILE"
    notify-send "Autoclicker" "Started (10 clicks/sec, left click)"
fi
