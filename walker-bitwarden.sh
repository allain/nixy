#!/usr/bin/env bash
# Bitwarden integration for walker
# Searches vault items and copies password/username/TOTP to clipboard

set -euo pipefail

SESSION_FILE="$HOME/.bw-session"
CLIP_TIMEOUT=15

notify() {
    notify-send -t 3000 "Bitwarden" "$1"
}

get_session() {
    if [ -f "$SESSION_FILE" ]; then
        export BW_SESSION
        BW_SESSION=$(cat "$SESSION_FILE")
        if bw unlock --check &>/dev/null; then
            return 0
        fi
    fi

    local status
    status=$(bw status 2>/dev/null | jq -r '.status')

    if [ "$status" = "unauthenticated" ]; then
        notify "Not logged in. Run: bw login"
        return 1
    fi

    local password
    password=$(echo "" | walker --dmenu --placeholder "Master Password" --password)
    [ -z "$password" ] && return 1

    local session
    session=$(bw unlock --raw "$password" 2>/dev/null) || {
        notify "Failed to unlock vault"
        return 1
    }

    echo "$session" > "$SESSION_FILE"
    chmod 600 "$SESSION_FILE"
    export BW_SESSION="$session"
}

copy_and_clear() {
    local value="$1"
    local label="$2"
    echo -n "$value" | wl-copy
    notify "$label copied (clears in ${CLIP_TIMEOUT}s)"
    (sleep "$CLIP_TIMEOUT" && echo -n "" | wl-copy) &
}

main() {
    get_session || exit 1

    bw sync &>/dev/null

    local items
    items=$(bw list items 2>/dev/null)

    local names
    names=$(echo "$items" | jq -r '.[] | select(.login != null) | .name + " (" + (.login.username // "no user") + ")"')

    [ -z "$names" ] && { notify "No items found"; exit 0; }

    local selected
    selected=$(echo "$names" | walker --dmenu --placeholder "Search vault...")
    [ -z "$selected" ] && exit 0

    # Extract the name part (before the last parenthetical)
    local item_name
    item_name=$(echo "$selected" | sed 's/ ([^)]*)[[:space:]]*$//')

    local action
    action=$(printf "Password\nUsername\nTOTP" | walker --dmenu --placeholder "Copy what?")
    [ -z "$action" ] && exit 0

    local item
    item=$(echo "$items" | jq -r --arg name "$item_name" 'map(select(.name == $name)) | first')

    case "$action" in
        Password)
            local pass
            pass=$(echo "$item" | jq -r '.login.password // empty')
            [ -z "$pass" ] && { notify "No password found"; exit 1; }
            copy_and_clear "$pass" "Password"
            ;;
        Username)
            local user
            user=$(echo "$item" | jq -r '.login.username // empty')
            [ -z "$user" ] && { notify "No username found"; exit 1; }
            copy_and_clear "$user" "Username"
            ;;
        TOTP)
            local totp
            totp=$(bw get totp "$(echo "$item" | jq -r '.id')" 2>/dev/null) || {
                notify "No TOTP configured"
                exit 1
            }
            copy_and_clear "$totp" "TOTP"
            ;;
    esac
}

main
