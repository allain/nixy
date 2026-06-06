#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="$HOME/.local/share/wallpapers/current.jpg"
CACHE="$HOME/.local/share/wallpapers/filelist-all-images.cache"
REPO="dharmx/walls"
BRANCH="main"

mkdir -p "$(dirname "$WALLPAPER")"

# Cache the file list for a day (avoids hitting the API every call)
if [ ! -s "$CACHE" ] || [ "$(find "$CACHE" -mmin +1440 2>/dev/null)" ]; then
  echo "Fetching file list from GitHub..."
  TMP_CACHE="${CACHE}.$$"
  trap 'rm -f "$TMP_CACHE"' EXIT

  if ! curl -sf "https://api.github.com/repos/$REPO/git/trees/$BRANCH?recursive=1" \
    | grep '"path"' \
    | grep -iE '\.(jpg|jpeg|png|webp)"' \
    | sed 's/.*"path": "//;s/".*//' \
    > "$TMP_CACHE"; then
    echo "Failed to fetch wallpaper file list."
    exit 1
  fi

  if [ ! -s "$TMP_CACHE" ]; then
    echo "No wallpapers found in fetched file list."
    exit 1
  fi

  mv "$TMP_CACHE" "$CACHE"
  trap - EXIT
fi

TOTAL=$(wc -l < "$CACHE")
if [ "$TOTAL" -eq 0 ]; then
  echo "No wallpapers found in file list."
  exit 1
fi

# Pick a random file
LINE=$((RANDOM % TOTAL + 1))
FILE=$(sed -n "${LINE}p" "$CACHE")

echo "Downloading: $FILE"
curl -sfL "https://raw.githubusercontent.com/$REPO/$BRANCH/$FILE" -o "$WALLPAPER"

echo "Setting wallpaper..."
awww img "$WALLPAPER" \
  --transition-type grow \
  --transition-duration 2 \
  --transition-fps 60
