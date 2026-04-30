#!/bin/sh
# Open foot terminal, inheriting CWD from focused foot window if applicable
if hyprctl activewindow -j | jq -e '.class == "foot"' > /dev/null 2>&1; then
  pid=$(hyprctl activewindow -j | jq '.pid')
  child=$(pgrep -oP "$pid" 2>/dev/null)
  cwd=$(readlink "/proc/$child/cwd" 2>/dev/null)
  exec foot --working-directory="${cwd:-$HOME}"
else
  exec foot
fi
