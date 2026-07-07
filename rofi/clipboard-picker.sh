#!/usr/bin/env sh

# Clipboard history picker: cliphist + rofi
# Enter copies the selection and pastes it into the focused window.

selection=$(cliphist list | rofi -dmenu -display-columns 2 -p "❯" -show-icons false \
  -theme-str 'textbox-mode-badge { content: "CLIPBOARD"; } element-icon { size: 0px; margin: 0; }')
[ -z "$selection" ] && exit 0

printf '%s' "$selection" | cliphist decode | wl-copy

# Give focus time to return to the previous window before pasting
sleep 0.2

class=$(hyprctl activewindow -j | jq -r '.class' | tr '[:upper:]' '[:lower:]')
case "$class" in
  kitty|alacritty|foot|org.wezfurlong.wezterm|com.mitchellh.ghostty)
    wtype -M ctrl -M shift v -m shift -m ctrl ;;
  *)
    wtype -M ctrl v -m ctrl ;;
esac
