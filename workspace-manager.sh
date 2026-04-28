#!/usr/bin/env bash
# Ensures waybar always shows occupied workspaces + 1 empty one
# by dynamically setting a persistent workspace rule in Hyprland.

PREV_NEXT=0

update() {
  max_ws=$(hyprctl workspaces -j | jq '[.[] | select(.windows > 0) | .id] | if length > 0 then max else 0 end')
  next_ws=$((max_ws + 1))

  if [ "$next_ws" -ne "$PREV_NEXT" ]; then
    if [ "$PREV_NEXT" -gt 0 ]; then
      hyprctl keyword workspace "$PREV_NEXT,persistent:false" >/dev/null 2>&1
    fi
    hyprctl keyword workspace "$next_ws,persistent:true" >/dev/null 2>&1
    PREV_NEXT=$next_ws
  fi
}

# Initial update
sleep 1
update

# Listen for relevant Hyprland events
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
  case "$line" in
    workspace*|destroyworkspace*|openwindow*|closewindow*|movewindow*)
      update
      ;;
  esac
done
