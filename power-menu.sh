#!/usr/bin/env bash
set -euo pipefail

choose() {
  walker --dmenu --placeholder "$1"
}

confirm() {
  local action="$1"
  local choice

  choice="$(printf 'No\nYes\n' | choose "$action?")"
  [ "$choice" = "Yes" ]
}

choice="$(
  printf '%s\n' \
    "Lock" \
    "Suspend" \
    "Hibernate" \
    "Log out" \
    "Reboot" \
    "Shut down" |
    choose "Power"
)"

[ -n "$choice" ] || exit 0

case "$choice" in
  "Lock")
    loginctl lock-session
    ;;
  "Suspend")
    loginctl lock-session
    systemctl suspend
    ;;
  "Hibernate")
    loginctl lock-session
    systemctl hibernate
    ;;
  "Log out")
    confirm "Log out" || exit 0
    uwsm stop
    ;;
  "Reboot")
    confirm "Reboot" || exit 0
    systemctl reboot
    ;;
  "Shut down")
    confirm "Shut down" || exit 0
    systemctl poweroff
    ;;
esac
