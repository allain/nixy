#!/usr/bin/env bash
# Set wallpaper with swww

WALLPAPER="$HOME/.config/hypr/bg.jpg"

# Ensure swww daemon is running
swww query &>/dev/null || swww-daemon &
sleep 0.5

swww img "$WALLPAPER" \
    --transition-type grow \
    --transition-duration 2 \
    --transition-fps 60
