# Nixy MACH-W29 Payload

This directory is the full USB payload. Copy its contents onto a USB stick, mount that USB on the target NixOS system, and run `install.sh`.

## What it installs

- NixOS `25.11`
- Hyprland started through UWSM
- `google-chrome`
- `neovim`
- `foot`
- `wofi`
- `waybar`
- `mako`
- `nodejs_22`
- `install-claude-code` helper for Anthropic's installer

## Contents

- `sync.sh`
- `flake.nix`
- `configuration.nix`
- `machine-mach-w29.nix`
- `identity.nix`
- `hyprland.conf`
- `waybar-config.jsonc`
- `waybar-style.css`
- `mako.conf`

## Sync

`sync.sh` performs a two-way sync between the USB, `/etc/nixos`, and `~/.config`:

1. **Pull**: manual changes made on the system (e.g. tweaking `~/.config/hypr/hyprland.conf`) are pulled back onto the USB.
2. **Push**: edits made on the USB are pushed into `/etc/nixos` and `~/.config`.
3. If a file changed on both sides, a diff is shown and you pick which to keep.
4. If any system files changed, `nixos-rebuild switch` runs automatically.

```bash
sudo /mnt/usb/sync.sh            # full sync + rebuild
sudo /mnt/usb/sync.sh --dry-run  # preview only
sudo /mnt/usb/sync.sh --no-rebuild
```

### Tracked dotconfig files

| USB file | `~/.config/` path |
|---|---|
| `hyprland.conf` | `~/.config/hypr/hyprland.conf` |
| `waybar-config.jsonc` | `~/.config/waybar/config.jsonc` |
| `waybar-style.css` | `~/.config/waybar/style.css` |
| `mako.conf` | `~/.config/mako/config` |
| `foot.ini` | `~/.config/foot/foot.ini` |

## Notes

- `sync.sh` preserves the local `hardware-configuration.nix` — it is never overwritten.
- Huawei-specific settings live in `machine-mach-w29.nix`.
- A `.last-sync` timestamp file on the USB tracks when the last sync happened.
- After first boot, run `passwd`, then `install-claude-code`.
