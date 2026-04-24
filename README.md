# Nixy MACH-W29 Payload

This directory is the full USB payload for a NixOS + Hyprland system on the Huawei MACH-W29. Copy its contents into `/etc/nixos` using `sync.sh` and rebuild.

## What it installs

- NixOS `25.11` with Home Manager
- Hyprland started through UWSM
- `google-chrome`
- `neovim` (NvChad)
- `foot`
- `wofi`
- `waybar`
- `mako`
- `nodejs_22`
- `claude-code`

## Contents

- `flake.nix` — flake inputs and NixOS module wiring
- `configuration.nix` — system-level NixOS config
- `home.nix` — user-level config via Home Manager (dotfiles, git)
- `machine-mach-w29.nix` — Huawei-specific hardware settings
- `identity.nix` — user identity (name, timezone, hostname)
- `hyprland.conf` — Hyprland config (managed by Home Manager)
- `waybar-config.jsonc` — Waybar config (managed by Home Manager)
- `waybar-style.css` — Waybar styles (managed by Home Manager)
- `mako.conf` — Mako notification config (managed by Home Manager)
- `foot.ini` — Foot terminal config (managed by Home Manager)
- `sync.sh` — syncs USB files to `/etc/nixos` and rebuilds

## Sync

`sync.sh` copies nix and config files from the USB into `/etc/nixos` and optionally runs `nixos-rebuild switch`. Dotfiles under `~/.config` are managed declaratively by Home Manager — no manual syncing needed.

```bash
sudo /mnt/usb/sync.sh            # sync + rebuild
sudo /mnt/usb/sync.sh --dry-run  # preview only
sudo /mnt/usb/sync.sh --no-rebuild
```

## Notes

- `sync.sh` preserves the local `hardware-configuration.nix` — it is never overwritten.
- Huawei-specific settings live in `machine-mach-w29.nix`.
- Dotfiles in `~/.config` are read-only symlinks managed by Home Manager. Edit the source files on the USB and rebuild to apply changes.
- After first boot, run `passwd` to set your password.
