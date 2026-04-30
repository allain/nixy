#!/usr/bin/env bash
# Set solid color wallpaper with swww

# Ensure swww daemon is running
swww query &>/dev/null || swww-daemon &
sleep 0.5

swww clear 181825
