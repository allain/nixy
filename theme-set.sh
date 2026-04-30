#!/usr/bin/env bash
set -euo pipefail

NIXY_DIR="$HOME/.config/nixy"
THEMES_DIR="$NIXY_DIR/themes"
TEMPLATES_DIR="$NIXY_DIR/templates"
CURRENT_THEME_FILE="$NIXY_DIR/current-theme"

# Explicit variable list for envsubst (avoids expanding $mod, $TIME, ${url}, etc.)
VARS='${base}${mantle}${crust}${surface0}${surface1}${surface2}${overlay0}${text}${subtext}${subtext2}${blue}${mauve}${green}${red}${peach}${yellow}${teal}${ansi_black}${ansi_red}${ansi_green}${ansi_yellow}${ansi_blue}${ansi_magenta}${ansi_cyan}${ansi_white}${ansi_brblack}${ansi_brred}${ansi_brgreen}${ansi_bryellow}${ansi_brblue}${ansi_brmagenta}${ansi_brcyan}${ansi_brwhite}'

list_themes() {
  for f in "$THEMES_DIR"/*.sh; do
    basename "$f" .sh
  done
}

if [ "${1:-}" = "--list" ]; then
  list_themes
  exit 0
fi

if [ "${1:-}" = "--current" ]; then
  cat "$CURRENT_THEME_FILE" 2>/dev/null || echo "no theme set"
  exit 0
fi

if [ -z "${1:-}" ]; then
  echo "Usage: theme-set <theme-name>"
  echo "       theme-set --list"
  echo "       theme-set --current"
  echo ""
  echo "Available themes:"
  list_themes
  exit 1
fi

THEME="$1"
THEME_FILE="$THEMES_DIR/$THEME.sh"

if [ ! -f "$THEME_FILE" ]; then
  echo "Unknown theme: $THEME"
  echo ""
  echo "Available themes:"
  list_themes
  exit 1
fi

# Source theme colors
# shellcheck disable=SC1090
source "$THEME_FILE"

# Export all color variables for envsubst
export base mantle crust surface0 surface1 surface2 overlay0
export text subtext subtext2
export blue mauve green red peach yellow teal
export ansi_black ansi_red ansi_green ansi_yellow ansi_blue ansi_magenta ansi_cyan ansi_white
export ansi_brblack ansi_brred ansi_brgreen ansi_bryellow ansi_brblue ansi_brmagenta ansi_brcyan ansi_brwhite

# Generate configs from templates
mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/foot" \
         "$HOME/.config/mako" "$HOME/.config/walker/themes"

envsubst "$VARS" < "$TEMPLATES_DIR/hyprland.conf.tpl"          > "$HOME/.config/hypr/hyprland.conf"
envsubst "$VARS" < "$TEMPLATES_DIR/waybar-style.css.tpl"       > "$HOME/.config/waybar/style.css"
envsubst "$VARS" < "$TEMPLATES_DIR/foot.ini.tpl"               > "$HOME/.config/foot/foot.ini"
envsubst "$VARS" < "$TEMPLATES_DIR/mako.conf.tpl"              > "$HOME/.config/mako/config"
envsubst "$VARS" < "$TEMPLATES_DIR/hyprlock.conf.tpl"          > "$HOME/.config/hypr/hyprlock.conf"
envsubst "$VARS" < "$TEMPLATES_DIR/walker-style.css.tpl"       > "$HOME/.config/walker/themes/catppuccin.css"
# Save current theme name
echo "$THEME" > "$CURRENT_THEME_FILE"

# Reload services (skip if not running, e.g. during bootstrap)
if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null 2>&1; then
  hyprctl reload
  pkill waybar 2>/dev/null; waybar &disown
  makoctl reload 2>/dev/null
  "$NIXY_DIR/wallpaper" 2>/dev/null
  pkill walker 2>/dev/null; walker --gapplication-service &disown
  notify-send "Theme" "Switched to ${theme_name:-$THEME}"
fi
