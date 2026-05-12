#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
SetWinDelay -1
SetControlDelay -1

; ============================================================
;  RectangleWin - Keyboard window snapping for Windows
;  Inspired by Rectangle / Spectacle / Square on macOS.
;
;  Repo:    https://github.com/junegu-glitch/RectangleWin
;  License: MIT
; ============================================================

global LastDir   := ""    ; "L", "R", "U", "D"
global LastHwnd  := 0
global LastStep  := 0     ; 0,1,2  -> 1/2, 1/3, 2/3
global UndoMap   := Map() ; hwnd -> {x,y,w,h}

A_IconTip := "RectangleWin"
TraySetIcon("imageres.dll", 109)

; ---- Tray menu ----
tray := A_TrayMenu
tray.Delete()
tray.Add("RectangleWin - shortcuts", (*) => ShowHelp())
tray.Add()
tray.Add("Reload", (*) => Reload())
tray.Add("Exit",   (*) => ExitApp())
tray.Default := "RectangleWin - shortcuts"

ShowHelp() {
    MsgBox(
        "Ctrl+Win+Enter    Fullscreen`n"
        . "Ctrl+Win+Left/Right    Left/Right cycle (1/2 -> 1/3 -> 2/3)`n"
        . "Ctrl+Win+Up/Down       Top/Bottom cycle (1/2 -> 1/3 -> 2/3)`n"
        . "Ctrl+Win+C        Smart center (auto by monitor orientation)`n"
        . "Ctrl+Win+H        Center column 1/3 (force, for 3-column layout)`n"
        . "Ctrl+Win+V        Middle row 1/3 (force, for 3-row layout)`n"
        . "Ctrl+Win+Numpad 7/9/1/3   Quarter corners`n"
        . "Ctrl+Win+Shift+Left/Right Move to prev/next monitor`n"
        . "Ctrl+Win+Z        Undo last snap`n"
        . "Ctrl+Win+T        Toggle Always-on-Top`n"
        , "RectangleWin")
}

; ============================================================
;  Helpers
; ============================================================

GetActiveHwnd() {
    try {
        hwnd := WinGetID("A")
        if !hwnd
            return 0
        ; skip desktop, shell windows
        cls := WinGetClass("ahk_id " hwnd)
        if (cls = "WorkerW" || cls = "Progman" || cls = "Shell_TrayWnd")
            return 0
        return hwnd
    } catch {
        return 0
    }
}

GetMonitorOf(hwnd) {
    ; returns monitor index whose work area contains the window's center.
    if !hwnd
        return MonitorGetPrimary()
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    cx := x + w // 2
    cy := y + h // 2
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &L, &T, &R, &B)
        if (cx >= L && cx < R && cy >= T && cy < B)
            return A_Index
    }
    return MonitorGetPrimary()
}

GetWorkAreaOf(hwnd) {
    n := GetMonitorOf(hwnd)
    MonitorGetWorkArea(n, &L, &T, &R, &B)
    return { L: L, T: T, R: R, B: B, W: R - L, H: B - T, N: n }
}

SaveUndo(hwnd) {
    if !hwnd
        return
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    UndoMap[hwnd] := { x: x, y: y, w: w, h: h }
}

Snap(hwnd, x, y, w, h) {
    if !hwnd
        return
    SaveUndo(hwnd)
    ; ensure restored from maximized/minimized
    try {
        state := WinGetMinMax("ahk_id " hwnd)
        if (state != 0)
            WinRestore("ahk_id " hwnd)
    }
    WinMove(x, y, w, h, "ahk_id " hwnd)
}

SetCycle(dir, hwnd) {
    ; advance cycle step if same dir+window, else reset
    global LastDir, LastHwnd, LastStep
    if (LastDir = dir && LastHwnd = hwnd)
        LastStep := Mod(LastStep + 1, 3)
    else
        LastStep := 0
    LastDir := dir
    LastHwnd := hwnd
    return LastStep   ; 0 -> 1/2, 1 -> 1/3, 2 -> 2/3
}

ResetCycle() {
    global LastDir, LastHwnd, LastStep
    LastDir := ""
    LastHwnd := 0
    LastStep := 0
}

; fraction for cycle step
StepFraction(step) {
    switch step {
        case 0: return 1/2
        case 1: return 1/3
        case 2: return 2/3
    }
    return 1/2
}

; ============================================================
;  Actions
; ============================================================

ActFullscreen(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, wa.W, wa.H)
}

ActLeft(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    step := SetCycle("L", hwnd)
    frac := StepFraction(step)
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, Round(wa.W * frac), wa.H)
}

ActRight(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    step := SetCycle("R", hwnd)
    frac := StepFraction(step)
    wa := GetWorkAreaOf(hwnd)
    w := Round(wa.W * frac)
    Snap(hwnd, wa.R - w, wa.T, w, wa.H)
}

ActUp(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    step := SetCycle("U", hwnd)
    frac := StepFraction(step)
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, wa.W, Round(wa.H * frac))
}

ActDown(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    step := SetCycle("D", hwnd)
    frac := StepFraction(step)
    wa := GetWorkAreaOf(hwnd)
    h := Round(wa.H * frac)
    Snap(hwnd, wa.L, wa.B - h, wa.W, h)
}

DoCenterColumn(hwnd, wa) {
    w := Round(wa.W / 3)
    Snap(hwnd, wa.L + Round((wa.W - w) / 2), wa.T, w, wa.H)
}

DoCenterRow(hwnd, wa) {
    h := Round(wa.H / 3)
    Snap(hwnd, wa.L, wa.T + Round((wa.H - h) / 2), wa.W, h)
}

; Smart center: picks column vs row based on monitor orientation.
ActCenterAuto(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    if (wa.W >= wa.H)
        DoCenterColumn(hwnd, wa)
    else
        DoCenterRow(hwnd, wa)
}

; Force center column 1/3 (for 3-column layouts), regardless of orientation.
ActCenterColumn(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    DoCenterColumn(hwnd, GetWorkAreaOf(hwnd))
}

; Force middle row 1/3 (for 3-row layouts), regardless of orientation.
ActMiddleRow(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    DoCenterRow(hwnd, GetWorkAreaOf(hwnd))
}

ActCornerTL(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, wa.W // 2, wa.H // 2)
}

ActCornerTR(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    w := wa.W // 2
    Snap(hwnd, wa.R - w, wa.T, w, wa.H // 2)
}

ActCornerBL(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    h := wa.H // 2
    Snap(hwnd, wa.L, wa.B - h, wa.W // 2, h)
}

ActCornerBR(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    w := wa.W // 2
    h := wa.H // 2
    Snap(hwnd, wa.R - w, wa.B - h, w, h)
}

ActUndo(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    if !UndoMap.Has(hwnd)
        return
    p := UndoMap[hwnd]
    UndoMap.Delete(hwnd)
    try {
        state := WinGetMinMax("ahk_id " hwnd)
        if (state != 0)
            WinRestore("ahk_id " hwnd)
    }
    WinMove(p.x, p.y, p.w, p.h, "ahk_id " hwnd)
    ResetCycle()
}

ActToggleAlwaysOnTop(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    WinSetAlwaysOnTop(-1, "ahk_id " hwnd)
}

; ---- Move to adjacent monitor preserving ratio within work area ----
MoveToMonitor(direction) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    count := MonitorGetCount()
    if (count < 2)
        return
    src := GetWorkAreaOf(hwnd)
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    ; ratio within source work area
    rx := (x - src.L) / src.W
    ry := (y - src.T) / src.H
    rw := w / src.W
    rh := h / src.H
    ; find target monitor by x-position
    targetIdx := FindAdjacentMonitor(src.N, direction)
    if (targetIdx = src.N)
        return
    MonitorGetWorkArea(targetIdx, &L, &T, &R, &B)
    tW := R - L, tH := B - T
    newX := Round(L + rx * tW)
    newY := Round(T + ry * tH)
    newW := Round(rw * tW)
    newH := Round(rh * tH)
    SaveUndo(hwnd)
    try {
        state := WinGetMinMax("ahk_id " hwnd)
        if (state != 0)
            WinRestore("ahk_id " hwnd)
    }
    WinMove(newX, newY, newW, newH, "ahk_id " hwnd)
    ResetCycle()
}

FindAdjacentMonitor(currentIdx, direction) {
    MonitorGetWorkArea(currentIdx, &cL, &cT, &cR, &cB)
    cCx := (cL + cR) // 2
    bestIdx := currentIdx
    bestDist := 0
    Loop MonitorGetCount() {
        if (A_Index = currentIdx)
            continue
        MonitorGetWorkArea(A_Index, &L, &T, &R, &B)
        cx := (L + R) // 2
        if (direction = "R" && cx > cCx) {
            d := cx - cCx
            if (bestDist = 0 || d < bestDist) {
                bestDist := d
                bestIdx := A_Index
            }
        } else if (direction = "L" && cx < cCx) {
            d := cCx - cx
            if (bestDist = 0 || d < bestDist) {
                bestDist := d
                bestIdx := A_Index
            }
        }
    }
    return bestIdx
}

ActMoveMonitorLeft(*)  => MoveToMonitor("L")
ActMoveMonitorRight(*) => MoveToMonitor("R")

; ============================================================
;  Hotkeys (Ctrl = ^, Win = #, Shift = +)
; ============================================================

^#Enter::      ActFullscreen()
^#Left::       ActLeft()
^#Right::      ActRight()
^#Up::         ActUp()
^#Down::       ActDown()
^#c::          ActCenterAuto()
^#h::          ActCenterColumn()
^#v::          ActMiddleRow()

^#Numpad7::    ActCornerTL()
^#Numpad9::    ActCornerTR()
^#Numpad1::    ActCornerBL()
^#Numpad3::    ActCornerBR()

^#+Left::      ActMoveMonitorLeft()
^#+Right::     ActMoveMonitorRight()

^#z::          ActUndo()
^#t::          ActToggleAlwaysOnTop()
