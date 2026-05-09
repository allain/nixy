# Network Recovery After Rebuild

## Quick Fix — Start NetworkManager

```bash
sudo systemctl start NetworkManager
sudo systemctl status NetworkManager
```

## If That Fails — Check Logs

```bash
journalctl -u NetworkManager -b --no-pager | tail -50
```

## Manual Network (No NetworkManager)

### Wired
```bash
# Find your interface name
ip link

# Bring it up
sudo ip link set enp0s31f6 up
sudo dhcpcd enp0s31f6
```

### WiFi
```bash
sudo ip link set wlp0s20f3 up
sudo wpa_supplicant -B -i wlp0s20f3 -c /etc/wpa_supplicant.conf
sudo dhcpcd wlp0s20f3
```

## Likely Root Cause

`system.stateVersion` in `configuration.nix` is set to `"25.11"`. This should be set to whatever NixOS version you **originally installed** (probably `"25.05"` or `"24.11"`). It is NOT meant to track your nixpkgs channel.

### Fix
1. Edit `configuration.nix`
2. Change `system.stateVersion = "25.11";` to your original install version
3. Rebuild: `sudo nixos-rebuild switch --flake .`

## Once Network Is Back

```bash
cd ~/personal/nixy
claude
```
