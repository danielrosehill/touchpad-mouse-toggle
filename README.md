# Touchpad Mouse Toggle (KDE Wayland)

Auto-disables the laptop touchpad when an external mouse is connected, and re-enables it when the mouse is disconnected.

## Why?

KDE Plasma has a built-in setting for this: **System Settings > Input Devices > Touchpad > "Disable touchpad when external mouse is connected"** (`DisableEventsOnExternalMouse`). However, on Wayland this setting doesn't reliably work — the touchpad stays enabled even when an external mouse is present. This script works around that by toggling the touchpad directly via KWin's DBus interface.

## Validated On

- **Laptop:** Lenovo ThinkPad E15 Gen 3 (20YG003DUS)
- **Touchpad:** ETPS/2 Elantech Touchpad
- **Mouse:** Logitech MX Vertical Advanced Ergonomic Mouse (USB wired)
- **OS:** Kubuntu, KDE Plasma 6.4.5, Wayland session
- **Kernel:** 6.17.0-14-generic
- **Date:** March 2026

Should also work with Bluetooth mice — the script detects mice through KWin's DBus interface which sees all input devices regardless of connection type.

## How It Works

1. Queries KWin via DBus for all input devices
2. Classifies each as touchpad, external mouse, or other (filters out virtual devices, TrackPoints, etc.)
3. If any external mice are found: disables all touchpads. Otherwise: enables them.

## Setup

### 1. The scripts

- `toggle-touchpad.sh` — main script, can be run manually
- `udev-trigger.sh` — wrapper called by udev (runs as root, re-invokes as your user)

### 2. Udev rule (auto-trigger on plug/unplug)

```bash
sudo cp 99-touchpad-toggle.rules /etc/udev/rules.d/
# Or create it:
sudo tee /etc/udev/rules.d/99-touchpad-toggle.rules << 'EOF'
ACTION=="add|remove", SUBSYSTEM=="input", ATTRS{id/vendor}!="0000", ENV{ID_INPUT_MOUSE}=="1", RUN+="/path/to/udev-trigger.sh"
EOF
sudo udevadm control --reload-rules
```

### 3. KDE Autostart (run on login)

```bash
cp touchpad-toggle.desktop ~/.config/autostart/
```

### 4. Disable KDE's built-in toggle

Since the built-in setting conflicts with this script, disable it in System Settings > Input Devices > Touchpad, or:

```bash
kwriteconfig6 --file kcminputrc --group 'Libinput' --group '2' --group '14' --group 'ETPS/2 Elantech Touchpad' --key DisableEventsOnExternalMouse false
```
