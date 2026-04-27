#!/usr/bin/env bash
# Re-tile windows on current workspace into a balanced grid
# 2 windows: side-by-side | 3: one column of 2 + one full | 4: 2x2 quadrants

workspace=$(hyprctl activeworkspace -j | jq '.id')
readarray -t addrs < <(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $workspace) | .address")

count=${#addrs[@]}
[ "$count" -le 1 ] && exit 0

# Move all windows to a temp special workspace
for addr in "${addrs[@]}"; do
    hyprctl dispatch movetoworkspacesilent "special:retile,address:$addr"
done

# Bring first window back (fills workspace — wide, so next split is horizontal)
hyprctl dispatch movetoworkspacesilent "$workspace,address:${addrs[0]}"

if [ "$count" -ge 2 ]; then
    # Second window splits horizontally with first → left | right columns
    hyprctl dispatch focuswindow "address:${addrs[0]}"
    hyprctl dispatch movetoworkspacesilent "$workspace,address:${addrs[1]}"
fi

if [ "$count" -ge 3 ]; then
    # Third window: focus left column so it splits vertically
    hyprctl dispatch focuswindow "address:${addrs[0]}"
    hyprctl dispatch movetoworkspacesilent "$workspace,address:${addrs[2]}"
fi

if [ "$count" -ge 4 ]; then
    # Fourth window: focus right column so it splits vertically → 2x2 grid
    hyprctl dispatch focuswindow "address:${addrs[1]}"
    hyprctl dispatch movetoworkspacesilent "$workspace,address:${addrs[3]}"
fi

# 5+ windows: distribute alternating between columns
for ((i=4; i<count; i++)); do
    if (( i % 2 == 0 )); then
        hyprctl dispatch focuswindow "address:${addrs[0]}"
    else
        hyprctl dispatch focuswindow "address:${addrs[1]}"
    fi
    hyprctl dispatch movetoworkspacesilent "$workspace,address:${addrs[$i]}"
done

# Reset all split ratios to equal
for addr in "${addrs[@]}"; do
    hyprctl dispatch focuswindow "address:$addr"
    hyprctl dispatch splitratio "exact 1.0"
done
