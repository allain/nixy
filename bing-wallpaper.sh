#!/usr/bin/env bash
# Fetch Bing's daily wallpaper and set it with swww

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
mkdir -p "$WALLPAPER_DIR"

# Get today's Bing wallpaper URL
json=$(curl -s "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US")
url_path=$(echo "$json" | jq -r '.images[0].url')

if [ -z "$url_path" ] || [ "$url_path" = "null" ]; then
    echo "Failed to fetch Bing wallpaper URL"
    exit 1
fi

url="https://www.bing.com${url_path}"
filename="$WALLPAPER_DIR/bing-$(date +%Y-%m-%d).jpg"

# Download if we don't already have today's
if [ ! -f "$filename" ]; then
    curl -sL "$url" -o "$filename"
fi

# Ensure swww daemon is running
swww query &>/dev/null || swww-daemon &

# Small delay for daemon startup on first run
sleep 0.5

# Set wallpaper with a smooth transition
swww img "$filename" \
    --transition-type grow \
    --transition-duration 2 \
    --transition-fps 60

# Clean up wallpapers older than 7 days
find "$WALLPAPER_DIR" -name "bing-*.jpg" -mtime +7 -delete
