# Changelog

## v0.1.5 — 2026-05-12

### Fixed
- **Same-monitor snaps no longer bounce windows to a different monitor.** v0.1.4's two-step move used the *old* window size at the *new* position for step 1. If the window was large (e.g. recently dragged from a 4K monitor), placing it at a new position on the FHD monitor caused the window rectangle to span both monitors, with the majority of the area on the wrong monitor. Windows' `MonitorFromRect` then reassigned the window to that monitor, triggering a spurious `WM_DPICHANGED` and the app jumped. New logic: the two-step move is only used when source and target monitors actually differ, and both steps use the final `(x, y, w, h)` — never the current size.
- **L-shape multi-monitor setups now navigate correctly.** `FindAdjacentMonitor` previously compared monitor center coordinates on a single axis, which could pick a far-away diagonal monitor as the "U/D/L/R" target. Now displacement in the orthogonal axis is penalized 2×, so monitors that are spatially aligned with the current one are preferred.

### Changed
- Per-hwnd state Maps (`UndoMap`, `SnapState`) are now garbage-collected every 60 seconds to drop entries for closed windows.

### Credits
- Diagnosis and patches reviewed by Gemini.

## v0.1.4 — 2026-05-12

### Fixed
- **Cross-monitor jumps now work across any DPI / orientation / monitor-count combination.** v0.1.3 introduced the correct architectural fix (re-apply the logical snap on the target monitor's work area instead of mapping ratios), but the low-level `WinMove` call was still being silently overridden by Windows' automatic `WM_DPICHANGED` rescale whenever the source and target monitors had different DPI scaling. The result was that a top-half window on a 100% monitor became a top-2/3 window after jumping to a 150% monitor (exactly the DPI ratio). This release fixes the underlying `Snap` primitive:
  - Forces per-monitor-aware V2 thread context (`SetThreadDpiAwarenessContext(-4)`) around every move/resize so all coordinates are interpreted as physical pixels.
  - Uses a two-step move when crossing monitors: first move the window with its current size so it crosses the DPI boundary, then resize on the target monitor's DPI context. The OS no longer gets a chance to scale our requested width/height.
- The fix is general: it doesn't assume a specific DPI ratio, monitor count, or orientation. Single-monitor users see no change (the second `WinMove` is a no-op when the position is unchanged from the source).

### Added (internal, off by default)
- Diagnostic logging via `DebugLog := true` flag at the top of the script. When enabled, every snap and monitor jump is recorded to `%LOCALAPPDATA%\RectangleWin\debug.log` with hwnd, monitor index, work area, and window rect. Off in releases; useful for troubleshooting reports.

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
