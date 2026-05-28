#!/bin/sh
# Open wezterm, inheriting CWD from focused terminal window if applicable
active=$(hyprctl activewindow -j 2>/dev/null)
class=$(printf '%s' "$active" | jq -r '.class // empty' 2>/dev/null)

case "$class" in
  org.wezfurlong.wezterm|foot)
    pid=$(printf '%s' "$active" | jq -r '.pid // empty')
    child=$(pgrep -oP "$pid" 2>/dev/null)
    cwd=$(readlink "/proc/$child/cwd" 2>/dev/null)
    ;;
esac

exec wezterm start --cwd "${cwd:-$HOME}"
