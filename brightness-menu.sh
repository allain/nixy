#!/usr/bin/env bash
set -euo pipefail

current="$(brightnessctl -m | awk -F, '{ gsub(/%/, "", $4); print $4 }')"

choice="$(
  {
    printf 'Current: %s%%\n' "$current"
    printf '10%%\n20%%\n30%%\n40%%\n50%%\n60%%\n70%%\n80%%\n90%%\n100%%\n'
  } | walker --dmenu --placeholder "Brightness"
)"

[ -n "$choice" ] || exit 0

case "$choice" in
  Current:*) exit 0 ;;
  *%) brightnessctl set "$choice" ;;
  *) brightnessctl set "$choice%" ;;
esac

notify-send "Brightness" "$(brightnessctl -m | awk -F, '{ print $4 }')"
