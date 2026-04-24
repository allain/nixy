#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sudo ./sync.sh [options]

Two-way sync between this USB payload, /etc/nixos, and the user's ~/.config.

1. Pulls manual changes from the system back onto the USB
2. Pushes USB-side edits into /etc/nixos and ~/.config
3. Optionally rebuilds the system

When a file has been modified on both sides since the last sync, the script
shows a diff and asks which version to keep.

Options:
  --target DIR              NixOS config directory (default: /etc/nixos)
  --user USER               User whose ~/.config to sync (default: from identity.nix)
  --no-rebuild              Sync files only; skip nixos-rebuild
  --dry-run                 Show what would change without modifying anything
  -h, --help                Show this help text
EOF
}

require_root() {
  if [[ ${EUID} -ne 0 ]]; then
    echo "Run this script as root." >&2
    exit 1
  fi
}

require_cmds() {
  local missing=()
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if (( ${#missing[@]} > 0 )); then
    printf 'Missing required commands: %s\n' "${missing[*]}" >&2
    exit 1
  fi
}

target_dir="/etc/nixos"
run_rebuild=1
dry_run=0
user_override=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)     target_dir="$2"; shift 2 ;;
    --user)       user_override="$2"; shift 2 ;;
    --no-rebuild) run_rebuild=0; shift ;;
    --dry-run)    dry_run=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_root
require_cmds rsync diff

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Read username from identity.nix
if [[ -n "$user_override" ]]; then
  cfg_user="$user_override"
else
  cfg_user="$(sed -n 's/.*userName *= *"\([^"]*\)".*/\1/p' "$script_dir/identity.nix")"
  if [[ -z "$cfg_user" ]]; then
    echo "Could not read userName from identity.nix. Use --user." >&2
    exit 1
  fi
fi
user_home="/home/$cfg_user"

# ── File mappings ──
# Each entry: usb_relative_path|system_absolute_path
# NixOS config files (USB <-> /etc/nixos)
nix_files=(
  "flake.nix|${target_dir}/flake.nix"
  "configuration.nix|${target_dir}/configuration.nix"
  "machine-mach-w29.nix|${target_dir}/machine-mach-w29.nix"
  "identity.nix|${target_dir}/identity.nix"
)

# Dotconfig files (USB <-> /etc/nixos AND USB <-> ~/.config)
# These have TWO system locations: /etc/nixos (for rebuild) and ~/.config (live user config)
dot_files=(
  "hyprland.conf|${target_dir}/hyprland.conf|${user_home}/.config/hypr/hyprland.conf"
  "waybar-config.jsonc|${target_dir}/waybar-config.jsonc|${user_home}/.config/waybar/config.jsonc"
  "waybar-style.css|${target_dir}/waybar-style.css|${user_home}/.config/waybar/style.css"
  "mako.conf|${target_dir}/mako.conf|${user_home}/.config/mako/config"
  "foot.ini|${target_dir}/foot.ini|${user_home}/.config/foot/foot.ini"
)

# Validate
if [[ ! -d "$target_dir" ]]; then
  printf 'Target config directory does not exist: %s\n' "$target_dir" >&2
  exit 1
fi
if [[ ! -f "$target_dir/hardware-configuration.nix" ]]; then
  printf 'Expected existing hardware config: %s/hardware-configuration.nix\n' "$target_dir" >&2
  exit 1
fi

for entry in "${nix_files[@]}" "${dot_files[@]}"; do
  usb_rel="${entry%%|*}"
  if [[ ! -f "$script_dir/$usb_rel" ]]; then
    printf 'Missing payload file on USB: %s\n' "$usb_rel" >&2
    exit 1
  fi
done

sync_stamp="$script_dir/.last-sync"

# ── Compare one file pair ──
# Sets: verdict = "same" | "push" | "pull" | "conflict"
compare_pair() {
  local usb_file="$1" sys_file="$2"

  if [[ ! -f "$sys_file" ]]; then
    verdict="push"
    return
  fi
  if diff -q "$usb_file" "$sys_file" >/dev/null 2>&1; then
    verdict="same"
    return
  fi
  # Files differ — check timestamps vs last sync
  if [[ ! -f "$sync_stamp" ]]; then
    verdict="conflict"
    return
  fi
  local usb_newer=0 sys_newer=0
  [[ "$usb_file" -nt "$sync_stamp" ]] && usb_newer=1
  [[ "$sys_file" -nt "$sync_stamp" ]] && sys_newer=1

  if (( usb_newer && sys_newer )); then
    verdict="conflict"
  elif (( usb_newer )); then
    verdict="push"
  elif (( sys_newer )); then
    verdict="pull"
  else
    verdict="conflict"
  fi
}

# ── Collect actions ──
declare -A actions  # key=description, value="push|pull|skip"
declare -A push_pairs  # key=index, value="src|dst"
declare -A pull_pairs

push_idx=0
pull_idx=0

report_lines=()
has_changes=0

add_action() {
  local label="$1" usb_file="$2" sys_file="$3" verdict="$4"
  case "$verdict" in
    same) return ;;
    push)
      report_lines+=("  -> $label")
      push_pairs[$push_idx]="$usb_file|$sys_file"
      ((push_idx++)) || true
      has_changes=1
      ;;
    pull)
      report_lines+=("  <- $label")
      pull_pairs[$pull_idx]="$sys_file|$usb_file"
      ((pull_idx++)) || true
      has_changes=1
      ;;
    conflict)
      report_lines+=("  !! $label  (CONFLICT)")
      # Defer to interactive resolution
      conflict_entries+=("$label|$usb_file|$sys_file")
      has_changes=1
      ;;
  esac
}

conflict_entries=()

# Process nix-only files
for entry in "${nix_files[@]}"; do
  IFS='|' read -r usb_rel sys_path <<< "$entry"
  usb_file="$script_dir/$usb_rel"
  compare_pair "$usb_file" "$sys_path"
  add_action "$usb_rel (nixos)" "$usb_file" "$sys_path" "$verdict"
done

# Process dotconfig files — compare USB against ~/.config (the live user copy)
# /etc/nixos copy will be force-synced to match USB after resolution
for entry in "${dot_files[@]}"; do
  IFS='|' read -r usb_rel nix_path dot_path <<< "$entry"
  usb_file="$script_dir/$usb_rel"
  compare_pair "$usb_file" "$dot_path"
  add_action "$usb_rel (dotconfig)" "$usb_file" "$dot_path" "$verdict"
done

# ── Report ──
echo "=== Sync Report ==="
echo ""
if (( ! has_changes )); then
  echo "Everything is in sync. Nothing to do."
  exit 0
fi

printf '%s\n' "${report_lines[@]}"
echo ""

if (( dry_run )); then
  echo "(dry-run — no changes made)"
  exit 0
fi

# ── Resolve conflicts ──
for c in "${conflict_entries[@]}"; do
  IFS='|' read -r label usb_file sys_file <<< "$c"
  echo "--- CONFLICT: $label ---"
  echo "  USB:    $usb_file"
  echo "  System: $sys_file"
  diff --color=auto -u "$usb_file" "$sys_file" || true
  echo ""
  while true; do
    read -rp "Keep [u]sb version, [s]ystem version, or [S]kip? " choice
    case "$choice" in
      u|U)
        push_pairs[$push_idx]="$usb_file|$sys_file"
        ((push_idx++)) || true
        break ;;
      s)
        pull_pairs[$pull_idx]="$sys_file|$usb_file"
        ((pull_idx++)) || true
        break ;;
      S)
        echo "  Skipped."
        break ;;
      *) echo "  Enter u, s, or S" ;;
    esac
  done
done

# ── Apply ──
any_system_change=0

# Pull: system -> USB
for key in "${!pull_pairs[@]}"; do
  IFS='|' read -r src dst <<< "${pull_pairs[$key]}"
  printf 'pull  %s -> %s\n' "$src" "$dst"
  rsync -a "$src" "$dst"
done

# Push: USB -> system
for key in "${!push_pairs[@]}"; do
  IFS='|' read -r src dst <<< "${push_pairs[$key]}"
  printf 'push  %s -> %s\n' "$src" "$dst"
  mkdir -p "$(dirname "$dst")"
  rsync -a "$src" "$dst"
  chmod 0644 "$dst"
  # Fix ownership for user dotfiles
  if [[ "$dst" == "${user_home}/"* ]]; then
    chown "${cfg_user}:users" "$dst"
  fi
  any_system_change=1
done

# Also sync dotconfig files to /etc/nixos to keep all three in agreement
for entry in "${dot_files[@]}"; do
  IFS='|' read -r usb_rel nix_path dot_path <<< "$entry"
  usb_file="$script_dir/$usb_rel"
  if ! diff -q "$usb_file" "$nix_path" >/dev/null 2>&1; then
    printf 'sync  %s -> %s\n' "$usb_file" "$nix_path"
    rsync -a "$usb_file" "$nix_path"
    chmod 0644 "$nix_path"
    any_system_change=1
  fi
done

# Update sync timestamp
touch "$sync_stamp"

echo ""
echo "Sync complete."

if (( any_system_change && run_rebuild )); then
  echo ""
  echo "System files changed — running nixos-rebuild switch..."
  require_cmds nixos-rebuild
  nixos-rebuild switch --flake "${target_dir}#mach-w29"
elif (( any_system_change && ! run_rebuild )); then
  echo ""
  echo "System files changed but --no-rebuild was set."
  echo "Run manually:  sudo nixos-rebuild switch --flake ${target_dir}#mach-w29"
fi
