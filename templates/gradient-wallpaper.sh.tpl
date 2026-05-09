#!/usr/bin/env bash
# Set solid color wallpaper with awww

# Ensure awww daemon is running
awww query &>/dev/null || awww-daemon &
sleep 0.5

awww clear ${mantle}
