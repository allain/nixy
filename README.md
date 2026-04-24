# Nixy MACH-W29 Payload

Portable NixOS + Hyprland configuration for the Huawei MACH-W29. Rebuild directly from this USB drive — no copying needed.

## Usage

```bash
sudo nixos-rebuild switch --flake /mnt/usb#mach-w29 --impure
```

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

## Notes

- `hardware-configuration.nix` is referenced from `/etc/nixos/` — it stays on the machine, not the USB.
- Huawei-specific settings live in `machine-mach-w29.nix`.
- Dotfiles in `~/.config` are read-only symlinks managed by Home Manager. Edit the source files on the USB and rebuild to apply changes.
- After first boot, run `passwd` to set your password.
