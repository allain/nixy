#!/bin/sh
# Open wezterm, inheriting CWD from focused terminal window if applicable
active=$(hyprctl activewindow -j 2>/dev/null)
class=$(printf '%s' "$active" | jq -r '.class // empty' 2>/dev/null)

file_uri_to_path() {
  python3 -c 'import sys, urllib.parse
uri = sys.argv[1]
parsed = urllib.parse.urlparse(uri)
print(urllib.parse.unquote(parsed.path if parsed.scheme == "file" else uri))
' "$1"
}

case "$class" in
  org.wezfurlong.wezterm)
    pid=$(printf '%s' "$active" | jq -r '.pid // empty')
    pane_id=$(
      wezterm cli list-clients --format json 2>/dev/null |
        jq -r --argjson pid "$pid" '.[] | select(.pid == $pid) | .focused_pane_id' 2>/dev/null |
        head -n 1
    )
    if [ -n "$pane_id" ]; then
      cwd_uri=$(
        wezterm cli list --format json 2>/dev/null |
          jq -r --argjson pane_id "$pane_id" '.[] | select(.pane_id == $pane_id) | .cwd // empty' 2>/dev/null |
          head -n 1
      )
      [ -n "$cwd_uri" ] && cwd=$(file_uri_to_path "$cwd_uri")
    fi
    ;;
  foot)
    pid=$(printf '%s' "$active" | jq -r '.pid // empty')
    child=$(pgrep -oP "$pid" 2>/dev/null)
    cwd=$(readlink "/proc/$child/cwd" 2>/dev/null)
    ;;
esac

exec wezterm start --cwd "${cwd:-$HOME}"
