#!/usr/bin/env sh

while true; do
  emoji=$(rofimoji --action print --prompt "❯" \
    --selector-args '-theme-str "element-icon { size: 0px; margin: 0; }" -show-icons false')
  [ -z "$emoji" ] && break
  wtype "$emoji"
done
