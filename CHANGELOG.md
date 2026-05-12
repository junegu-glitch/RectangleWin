# Changelog

## v0.1.3 — 2026-05-12

### Fixed
- **Snap state is now preserved across monitor jumps.** Previously, moving a window between monitors used a ratio-based mapping (window position/size as a fraction of the source work area, re-applied on the target). On setups with different DPI scales (e.g. portrait FHD ↔ landscape 4K), DWM invisible borders, or taskbar differences, this produced visible drift — a top-half window would become top 2/3, and repeated jumps compounded the error.
- The new behavior records the logical snap (e.g. `top half`, `left 1/3`, `bottom-right quarter`) when a snap shortcut is pressed, and re-applies that same logical snap on the target monitor's work area. Result: top-half stays top-half regardless of DPI or aspect ratio differences, with no compounding drift across repeated jumps.
- If a window has no recorded snap state (e.g. user dragged it manually), the monitor-jump now keeps its size and places it at the target monitor's center instead of trying to scale it.

## v0.1.2 — 2026-05-12

### Added
- `Ctrl+Win+Shift+Up` / `Ctrl+Win+Shift+Down` — move window to the monitor above / below the current one. Useful for vertically-stacked monitor setups (laptop + external display on top, etc.).

### Changed
- Monitor-jump shortcuts are now described as directional ("the monitor on the left/right/above/below"), not "previous/next". Behavior of the existing left/right shortcuts is unchanged — it was already position-based.

## v0.1.1 — 2026-05-12

### Changed
- `Ctrl+Win+C` is now **orientation-aware**: on a landscape monitor it snaps to the center column 1/3 (previous behavior); on a portrait monitor it snaps to the middle row 1/3. One key, the right thing on either monitor.

### Added
- `Ctrl+Win+H` — force center column 1/3 regardless of monitor orientation (for landscape-style 3-column layouts on a portrait monitor).

### Notes
- `Ctrl+Win+V` is unchanged — still forces the middle row 1/3 (for portrait-style 3-row layouts on a landscape monitor).

## v0.1.0 — 2026-05-12

Initial release.

### Features
- Fullscreen snap (`Ctrl+Win+Enter`)
- Edge cycle: half → third → two-thirds (`Ctrl+Win+←/→/↑/↓`)
- Center column 1/3 (`Ctrl+Win+C`) — for 3-column layouts
- Middle row 1/3 (`Ctrl+Win+V`) — for 3-row layouts
- Quarter corners on numpad (`Ctrl+Win+Numpad 7/9/1/3`)
- Move window to adjacent monitor, preserving size ratio (`Ctrl+Win+Shift+←/→`)
- Undo last snap (`Ctrl+Win+Z`)
- Toggle Always-on-Top (`Ctrl+Win+T`)
- Tray icon with shortcut cheat sheet
