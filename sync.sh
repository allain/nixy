#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: sudo ./sync.sh [options]

Syncs NixOS configuration files from this USB payload into /etc/nixos
and optionally rebuilds the system.

Options:
  --target DIR              NixOS config directory (default: /etc/nixos)
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

target_dir="/etc/nixos"
run_rebuild=1
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)     target_dir="$2"; shift 2 ;;
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

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Files to sync from USB to /etc/nixos
nix_files=(
  flake.nix
  configuration.nix
  home.nix
  machine-mach-w29.nix
  identity.nix
  hyprland.conf
  waybar-config.jsonc
  waybar-style.css
  mako.conf
  foot.ini
)

# Validate
if [[ ! -d "$target_dir" ]]; then
  printf 'Target config directory does not exist: %s\n' "$target_dir" >&2
  exit 1
fi

for f in "${nix_files[@]}"; do
  if [[ ! -f "$script_dir/$f" ]]; then
    printf 'Missing payload file on USB: %s\n' "$f" >&2
    exit 1
  fi
done

# Compare and sync
has_changes=0

for f in "${nix_files[@]}"; do
  src="$script_dir/$f"
  dst="$target_dir/$f"

  if [[ ! -f "$dst" ]] || ! diff -q "$src" "$dst" >/dev/null 2>&1; then
    printf '  -> %s\n' "$f"
    has_changes=1
    if (( ! dry_run )); then
      cp "$src" "$dst"
      chmod 0644 "$dst"
    fi
  fi
done

if (( ! has_changes )); then
  echo "Everything is in sync. Nothing to do."
  exit 0
fi

if (( dry_run )); then
  echo ""
  echo "(dry-run — no changes made)"
  exit 0
fi

echo ""
echo "Sync complete."

if (( run_rebuild )); then
  echo ""
  echo "Running nixos-rebuild switch..."
  nixos-rebuild switch --flake "${target_dir}#mach-w29"
else
  echo ""
  echo "System files changed but --no-rebuild was set."
  echo "Run manually:  sudo nixos-rebuild switch --flake ${target_dir}#mach-w29"
fi
