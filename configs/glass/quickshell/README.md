# Quickshell

The bar, launcher, power menu, wallpaper picker, notifications and OSDs for the glass theme.

## Layout

- `shell.qml` starts everything
- `Bar/` the bar and its menus
- `Overlays/` full-screen or floating windows: launcher, power menu, wallpaper picker, notifications, OSD
- `Services/` where the data comes from
- `Widgets/` shared pieces: `BarPopup`, `Label`, `Icon`, `Dial`, `BatteryIcon`, `PopupGauge` and the popup rows
- `Common/` `Config` (paths and commands), `Glass` (colours, fonts, sizes), `PopupState`, `SysDir`

## Where the data comes from

Nothing here is tied to one distro or one vendor's tools, except where noted.

| What | From |
|---|---|
| Wi-Fi | NetworkManager, through `Quickshell.Networking` |
| Bluetooth | BlueZ, through `Quickshell.Bluetooth` |
| Power profile | power-profiles-daemon, through `PowerProfiles` |
| Volume | PipeWire |
| Battery | `/sys/class/power_supply` |
| Backlight | `/sys/class/backlight`, firmware before platform before raw |
| CPU load, memory | `/proc/stat`, `/proc/meminfo` |
| CPU temperature | `/sys/class/hwmon` (`coretemp`, `k10temp` or `zenpower`) |
| GPUs | `/sys/class/drm`. NVIDIA through `nvidia-smi`, only while the card is awake. Intel load is clock against max clock. AMD from its sysfs files, untested |
| Monitors | Hyprland. The bar writes changes to `~/.local/state/dotfiles/monitors.json` and reloads Hyprland, `hyprland/monitors.lua` reads it with `monitor-conf.json` |
| Headset battery | `~/.local/share/dotfiles/scripts/nari-essential-battery` (`scripts/nari-essential-battery.py`) |
| Wallpapers | `~/.local/share/dotfiles/scripts/wallpaper` (`scripts/wallpaper.sh`, awww and mpvpaper) |

## Needs

Hyprland with the Lua config, NetworkManager, BlueZ, power-profiles-daemon, PipeWire, `hyprlock`, the fonts in `fonts-1B.nix` (Material Symbols, Symbols Nerd Font, and fontconfig defaults for `sans-serif` and `monospace`), and `nvidia-smi` on NVIDIA machines.
