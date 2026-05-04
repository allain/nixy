#!/usr/bin/env bash
set -euo pipefail

current="$(hyprctl getoption cursor:zoom_factor | awk '/float:/ { print $2 }')"

if awk "BEGIN { exit !($current > 1.01) }"; then
  hyprctl keyword cursor:zoom_factor 1
else
  hyprctl keyword cursor:zoom_factor 2.5
fi
