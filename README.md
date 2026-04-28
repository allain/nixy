# Nixy USB Payload

Portable NixOS + Hyprland configuration for multiple machines. Rebuild directly from this USB drive — no copying needed.

## Supported hosts

| Host | Machine |
|------|---------|
| `mach-w29` | Huawei MACH-W29 |
| `nuc` | Intel NUC8i7HVK |

## Usage

```bash
sudo nixos-rebuild switch --flake /mnt/usb#<host> --impure
```

## What it installs

- NixOS `25.11` with Home Manager
- Hyprland started through UWSM
- `google-chrome`, `mattermost-desktop`, `bitwarden-desktop`
- `neovim` (NvChad), `helix`, `vscode`
- `foot` terminal
- `walker` (app launcher)
- `waybar`, `mako`, `swww` (wallpaper)
- `claude-code`, `deno`, `nodejs_22`, `python3`, `zig`
- `lazygit`, `lazydocker`
- `nwg-displays` (monitor management)

## Contents

- `flake.nix` — flake inputs and NixOS module wiring
- `configuration.nix` — system-level NixOS config
- `home.nix` — user-level config via Home Manager (dotfiles, git)
- `machine-mach-w29.nix` — Huawei MACH-W29 hardware settings
- `machine-nuc8i7hvk.nix` — Intel NUC8i7HVK hardware settings
- `identity.nix` — user identity (name, timezone, hostname)
- `hyprland.conf` — Hyprland config (managed by Home Manager)
- `waybar-config.jsonc` — Waybar config (managed by Home Manager)
- `waybar-style.css` — Waybar styles (managed by Home Manager)
- `mako.conf` — Mako notification config (managed by Home Manager)
- `foot.ini` — Foot terminal config (managed by Home Manager)
- `walker-config.toml` — Walker launcher config (managed by Home Manager)
- `walker-style.css` — Walker theme CSS (managed by Home Manager)
- `walker-theme.json` — Walker theme (managed by Home Manager)
- `walker-bitwarden.sh` — Bitwarden integration script
- `bing-wallpaper.sh` — Daily Bing wallpaper fetcher
- `justfile` — Task runner commands

## Notes

- `hardware-configuration.nix` is referenced from `/etc/nixos/` — it stays on the machine, not the USB.
- Machine-specific settings live in `machine-*.nix` files.
- Dotfiles in `~/.config` are read-only symlinks managed by Home Manager. Edit the source files on the USB and rebuild to apply changes.
- After first boot, run `passwd` to set your password.
