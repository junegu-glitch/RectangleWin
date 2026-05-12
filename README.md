# RectangleWin

**Keyboard-driven window snapping for Windows, inspired by [Rectangle](https://rectangleapp.com/), [Spectacle](https://www.spectacleapp.com/), and Square on macOS.**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Latest release](https://img.shields.io/github/v/release/junegu-glitch/RectangleWin?include_prereleases)](https://github.com/junegu-glitch/RectangleWin/releases)
[![Downloads](https://img.shields.io/github/downloads/junegu-glitch/RectangleWin/total)](https://github.com/junegu-glitch/RectangleWin/releases)

A small AutoHotkey v2 script that brings the Rectangle / Spectacle muscle memory to Windows. Press `Ctrl+Win+←` and the active window snaps to the left half. Press it again — it cycles to a third. Again — two-thirds. That's it.

If you've moved from macOS to Windows and missed your keyboard window manager, this is for you.

---

## Why not FancyZones / AltSnap / AquaSnap?

| | RectangleWin | PowerToys FancyZones | AltSnap | AquaSnap |
|---|---|---|---|---|
| Keyboard-first | yes | drag-first | drag-only | mostly drag |
| Zero setup (no zones to define) | yes | no | yes | yes |
| Rectangle/Spectacle shortcuts | yes | no | no | no |
| Cycle: 1/2 -> 1/3 -> 2/3 | yes | no | no | no |
| Undo last snap | yes | no | no | no |
| Single file, easy to hack | yes | no | no | no |

FancyZones is great if you want to define custom zones with the mouse. RectangleWin is for people who just want `Ctrl+Win+Left` to do the right thing every time, no setup.

---

## Install

### Option A — Run the `.ahk` (recommended)

1. Install [AutoHotkey v2](https://www.autohotkey.com/) (2.0 or later).
2. Download [`RectangleWin.ahk`](RectangleWin.ahk) from this repo.
3. Double-click it. Look for the RectangleWin icon in your system tray.

### Option B — Autostart on boot

After Option A, register it in the Startup folder:

1. Press `Win+R`, type `shell:startup`, hit Enter.
2. Drop a shortcut to `RectangleWin.ahk` (or to `AutoHotkey64.exe "<path>\RectangleWin.ahk"`) into that folder.

A standalone `.exe` build is planned for v0.2.0.

---

## Shortcuts

All shortcuts use `Ctrl+Win` as the base modifier. Snapping respects the work area of the monitor the window is currently on (taskbar excluded).

### Basic snapping

| Shortcut | Action |
|---|---|
| `Ctrl+Win+Enter` | Fullscreen (fills work area) |
| `Ctrl+Win+Left` | Left edge — cycles 1/2 -> 1/3 -> 2/3 |
| `Ctrl+Win+Right` | Right edge — cycles 1/2 -> 1/3 -> 2/3 |
| `Ctrl+Win+Up` | Top edge — cycles 1/2 -> 1/3 -> 2/3 |
| `Ctrl+Win+Down` | Bottom edge — cycles 1/2 -> 1/3 -> 2/3 |
| `Ctrl+Win+C` | Smart center — picks column or row 1/3 based on monitor orientation |
| `Ctrl+Win+H` | Force center column 1/3 (for 3-column layouts) |
| `Ctrl+Win+V` | Force middle row 1/3 (for 3-row layouts) |

### Quarter corners (numpad)

| Shortcut | Action |
|---|---|
| `Ctrl+Win+Numpad7` | Top-left quarter |
| `Ctrl+Win+Numpad9` | Top-right quarter |
| `Ctrl+Win+Numpad1` | Bottom-left quarter |
| `Ctrl+Win+Numpad3` | Bottom-right quarter |

### Multi-monitor

| Shortcut | Action |
|---|---|
| `Ctrl+Win+Shift+Left` | Move window to the monitor on the left (preserves size ratio) |
| `Ctrl+Win+Shift+Right` | Move window to the monitor on the right |
| `Ctrl+Win+Shift+Up` | Move window to the monitor above |
| `Ctrl+Win+Shift+Down` | Move window to the monitor below |

If no monitor exists in that direction, nothing happens.

### Utility

| Shortcut | Action |
|---|---|
| `Ctrl+Win+Z` | Undo last snap (restore previous position/size) |
| `Ctrl+Win+T` | Toggle Always-on-Top |

### Tips

- **Three-column layout** (landscape monitor): `Ctrl+Win+Left` twice (-> 1/3), then `Ctrl+Win+C`, then `Ctrl+Win+Right` twice on another window. Three equal columns.
- **Three-row layout** (portrait monitor): same idea with `Up`, `C`, `Down` — on a portrait monitor `Ctrl+Win+C` automatically picks the row 1/3.
- Need to force the opposite of what auto picks? Use `Ctrl+Win+H` (column) or `Ctrl+Win+V` (row) explicitly.

---

## Customizing

It's a single AutoHotkey v2 file — open `RectangleWin.ahk` in any text editor and rebind whatever you want. The hotkey block is at the bottom:

```ahk
^#Enter::      ActFullscreen()
^#Left::       ActLeft()
```

`^` = Ctrl, `#` = Win, `+` = Shift, `!` = Alt. See the [AutoHotkey hotkey reference](https://www.autohotkey.com/docs/v2/Hotkeys.htm).

---

## Roadmap

- v0.2.0 — Pre-built `.exe` (Ahk2Exe), so no AutoHotkey install required
- v0.2.x — Layout presets (save/restore arrangements of windows)
- v0.3.x — Window transparency hotkeys, virtual desktop move
- Later — winget package, customizable config file

Suggestions welcome — open an issue.

---

## Credits

- [Rectangle](https://github.com/rxhanson/Rectangle) (macOS) — the spiritual parent
- [Spectacle](https://github.com/eczarny/spectacle) (macOS, archived) — the original
- Square (macOS) — the minimalist take
- [AutoHotkey v2](https://www.autohotkey.com/) — the runtime that makes this ~250 lines instead of thousands

---

## License

[MIT](LICENSE) (c) 2026 June Gu
