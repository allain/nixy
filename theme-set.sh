#!/usr/bin/env bash
set -euo pipefail

NIXY_DIR="$HOME/.config/nixy"
THEMES_DIR="$NIXY_DIR/themes"
TEMPLATES_DIR="$NIXY_DIR/templates"
CURRENT_THEME_FILE="$NIXY_DIR/current-theme"
CURSOR_THEME="Bibata-Modern-Classic"
CURSOR_SIZE="20"

# Explicit variable list for envsubst (avoids expanding $mod, $TIME, ${url}, etc.)
VARS='${base}${mantle}${crust}${surface0}${surface1}${surface2}${overlay0}${text}${subtext}${subtext2}${blue}${mauve}${green}${red}${peach}${yellow}${teal}${ansi_black}${ansi_red}${ansi_green}${ansi_yellow}${ansi_blue}${ansi_magenta}${ansi_cyan}${ansi_white}${ansi_brblack}${ansi_brred}${ansi_brgreen}${ansi_bryellow}${ansi_brblue}${ansi_brmagenta}${ansi_brcyan}${ansi_brwhite}'

list_themes() {
  for f in "$THEMES_DIR"/*.sh; do
    basename "$f" .sh
  done
}

start_detached() {
  local log_file="$1"
  shift

  mkdir -p "$(dirname "$log_file")"
  nohup "$@" >"$log_file" 2>&1 &
  disown
}

stop_process() {
  local pattern="$1"
  local name="$2"

  pkill -TERM -f "$pattern" 2>/dev/null || true

  for _ in {1..30}; do
    if ! pgrep -f "$pattern" >/dev/null 2>&1; then
      return
    fi
    sleep 0.1
  done

  pkill -KILL -f "$pattern" 2>/dev/null || true

  for _ in {1..10}; do
    if ! pgrep -f "$pattern" >/dev/null 2>&1; then
      return
    fi
    sleep 0.1
  done

  echo "warning: could not stop $name cleanly" >&2
}

reload_session=1
reload_hyprland=0

while [ "${1:-}" = "--no-reload" ] || [ "${1:-}" = "--reload-hyprland" ]; do
  case "$1" in
    --no-reload)
      reload_session=0
      ;;
    --reload-hyprland)
      reload_hyprland=1
      ;;
  esac
  shift
done

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
  echo "       theme-set --no-reload <theme-name>"
  echo "       theme-set --reload-hyprland <theme-name>"
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

theme_variant="${theme_variant:-dark}"

# Export all color variables for envsubst
export base mantle crust surface0 surface1 surface2 overlay0
export text subtext subtext2
export blue mauve green red peach yellow teal
export ansi_black ansi_red ansi_green ansi_yellow ansi_blue ansi_magenta ansi_cyan ansi_white
export ansi_brblack ansi_brred ansi_brgreen ansi_bryellow ansi_brblue ansi_brmagenta ansi_brcyan ansi_brwhite

# Generate configs from templates
mkdir -p "$HOME/.config/hypr" "$HOME/.config/waybar" "$HOME/.config/foot" \
         "$HOME/.config/wezterm" \
         "$HOME/.config/mako" "$HOME/.config/walker/themes"

envsubst "$VARS" < "$TEMPLATES_DIR/hyprland.conf.tpl"          > "$HOME/.config/hypr/hyprland.conf"
envsubst "$VARS" < "$TEMPLATES_DIR/waybar-style.css.tpl"       > "$HOME/.config/waybar/style.css"
envsubst "$VARS" < "$TEMPLATES_DIR/foot.ini.tpl"               > "$HOME/.config/foot/foot.ini"
envsubst "$VARS" < "$TEMPLATES_DIR/wezterm.lua.tpl"            > "$HOME/.config/wezterm/wezterm.lua"
envsubst "$VARS" < "$TEMPLATES_DIR/mako.conf.tpl"              > "$HOME/.config/mako/config"
envsubst "$VARS" < "$TEMPLATES_DIR/hyprlock.conf.tpl"          > "$HOME/.config/hypr/hyprlock.conf"
envsubst "$VARS" < "$TEMPLATES_DIR/walker-style.css.tpl"       > "$HOME/.config/walker/themes/catppuccin.css"
# Save current theme name
echo "$THEME" > "$CURRENT_THEME_FILE"

if command -v gsettings &>/dev/null; then
  gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" 2>/dev/null || true

  if [ "$theme_variant" = "light" ]; then
    gsettings set org.gnome.desktop.interface color-scheme default 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita 2>/dev/null || true
  else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark 2>/dev/null || true
  fi
fi

if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null 2>&1; then
  hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" >/dev/null 2>&1 || true
fi

# Reload services (skip if not running, e.g. during bootstrap)
if [ "$reload_session" -eq 1 ] && command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null 2>&1; then
  if [ "$reload_hyprland" -eq 1 ]; then
    hyprctl reload >/dev/null
  fi
  stop_process '(^|/)(waybar|\.waybar-wrapped)( |$)' "waybar"
  start_detached "$HOME/.cache/nixy/waybar.log" waybar
  makoctl reload 2>/dev/null
  "$NIXY_DIR/wallpaper" 2>/dev/null
  # Prefer systemd-managed walker (auto-restart). Fall back to detached
  # start when the unit isn't active yet (e.g. first rebuild on a fresh
  # generation, or running theme-set outside a graphical session).
  if systemctl --user is-active --quiet walker.service 2>/dev/null; then
    systemctl --user restart walker.service
  else
    stop_process '(^|/)(walker|\.walker-wrapped)( |$)' "walker"
    if systemctl --user list-unit-files walker.service &>/dev/null; then
      systemctl --user start walker.service
    else
      start_detached "$HOME/.cache/nixy/walker.log" walker --gapplication-service
    fi
  fi
  notify-send "Theme" "Switched to ${theme_name:-$THEME}"
fi
