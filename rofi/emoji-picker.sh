#!/usr/bin/env sh

while true; do
  emoji=$(rofimoji --action print --prompt "❯" \
    --selector-args "-theme-str 'element-icon { size: 0px; margin: 0; } textbox-mode-badge { content: \"EMOJIS\"; }' -show-icons false")
  [ -z "$emoji" ] && break
  wtype "$emoji"
done
