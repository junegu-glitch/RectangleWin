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
global SnapState := Map() ; hwnd -> {kind, step}  -- preserved across monitor jumps

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
        . "Ctrl+Win+Shift+Arrows    Move to monitor in that direction`n"
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
    SnapState[hwnd] := { kind: "Full", step: 0 }
}

ActLeft(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    step := SetCycle("L", hwnd)
    frac := StepFraction(step)
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, Round(wa.W * frac), wa.H)
    SnapState[hwnd] := { kind: "L", step: step }
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
    SnapState[hwnd] := { kind: "R", step: step }
}

ActUp(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    step := SetCycle("U", hwnd)
    frac := StepFraction(step)
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, wa.W, Round(wa.H * frac))
    SnapState[hwnd] := { kind: "U", step: step }
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
    SnapState[hwnd] := { kind: "D", step: step }
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
    SnapState[hwnd] := { kind: "CenterAuto", step: 0 }
}

; Force center column 1/3 (for 3-column layouts), regardless of orientation.
ActCenterColumn(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    DoCenterColumn(hwnd, GetWorkAreaOf(hwnd))
    SnapState[hwnd] := { kind: "CenterCol", step: 0 }
}

; Force middle row 1/3 (for 3-row layouts), regardless of orientation.
ActMiddleRow(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    DoCenterRow(hwnd, GetWorkAreaOf(hwnd))
    SnapState[hwnd] := { kind: "CenterRow", step: 0 }
}

ActCornerTL(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    Snap(hwnd, wa.L, wa.T, wa.W // 2, wa.H // 2)
    SnapState[hwnd] := { kind: "TL", step: 0 }
}

ActCornerTR(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    w := wa.W // 2
    Snap(hwnd, wa.R - w, wa.T, w, wa.H // 2)
    SnapState[hwnd] := { kind: "TR", step: 0 }
}

ActCornerBL(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    ResetCycle()
    wa := GetWorkAreaOf(hwnd)
    h := wa.H // 2
    Snap(hwnd, wa.L, wa.B - h, wa.W // 2, h)
    SnapState[hwnd] := { kind: "BL", step: 0 }
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
    SnapState[hwnd] := { kind: "BR", step: 0 }
}

ActUndo(*) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    if !UndoMap.Has(hwnd)
        return
    p := UndoMap[hwnd]
    UndoMap.Delete(hwnd)
    if SnapState.Has(hwnd)
        SnapState.Delete(hwnd)
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

; ---- Apply a recorded snap state on a given work area ----
ApplySnapState(hwnd, wa, state) {
    switch state.kind {
        case "Full":
            Snap(hwnd, wa.L, wa.T, wa.W, wa.H)
        case "L":
            frac := StepFraction(state.step)
            Snap(hwnd, wa.L, wa.T, Round(wa.W * frac), wa.H)
        case "R":
            frac := StepFraction(state.step)
            w := Round(wa.W * frac)
            Snap(hwnd, wa.R - w, wa.T, w, wa.H)
        case "U":
            frac := StepFraction(state.step)
            Snap(hwnd, wa.L, wa.T, wa.W, Round(wa.H * frac))
        case "D":
            frac := StepFraction(state.step)
            h := Round(wa.H * frac)
            Snap(hwnd, wa.L, wa.B - h, wa.W, h)
        case "CenterAuto":
            if (wa.W >= wa.H)
                DoCenterColumn(hwnd, wa)
            else
                DoCenterRow(hwnd, wa)
        case "CenterCol":
            DoCenterColumn(hwnd, wa)
        case "CenterRow":
            DoCenterRow(hwnd, wa)
        case "TL":
            Snap(hwnd, wa.L, wa.T, wa.W // 2, wa.H // 2)
        case "TR":
            w := wa.W // 2
            Snap(hwnd, wa.R - w, wa.T, w, wa.H // 2)
        case "BL":
            h := wa.H // 2
            Snap(hwnd, wa.L, wa.B - h, wa.W // 2, h)
        case "BR":
            w := wa.W // 2
            h := wa.H // 2
            Snap(hwnd, wa.R - w, wa.B - h, w, h)
    }
}

; ---- Move to adjacent monitor: re-apply recorded snap state on target ----
MoveToMonitor(direction) {
    hwnd := GetActiveHwnd()
    if !hwnd
        return
    if (MonitorGetCount() < 2)
        return

    srcIdx := GetMonitorOf(hwnd)
    targetIdx := FindAdjacentMonitor(srcIdx, direction)
    if (targetIdx = srcIdx)
        return

    MonitorGetWorkArea(targetIdx, &L, &T, &R, &B)
    wa := { L: L, T: T, R: R, B: B, W: R - L, H: B - T, N: targetIdx }

    if SnapState.Has(hwnd) {
        ; Re-apply the same logical snap on the target monitor's work area.
        ; Independent of DPI / DWM borders / taskbar — no ratio drift.
        ApplySnapState(hwnd, wa, SnapState[hwnd])
    } else {
        ; No recorded snap state (user moved/resized manually): keep size,
        ; place at the target monitor's center.
        WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
        newX := wa.L + (wa.W - w) // 2
        newY := wa.T + (wa.H - h) // 2
        SaveUndo(hwnd)
        try {
            state := WinGetMinMax("ahk_id " hwnd)
            if (state != 0)
                WinRestore("ahk_id " hwnd)
        }
        WinMove(newX, newY, w, h, "ahk_id " hwnd)
    }
    ResetCycle()
}

FindAdjacentMonitor(currentIdx, direction) {
    MonitorGetWorkArea(currentIdx, &cL, &cT, &cR, &cB)
    cCx := (cL + cR) // 2
    cCy := (cT + cB) // 2
    bestIdx := currentIdx
    bestDist := 0
    Loop MonitorGetCount() {
        if (A_Index = currentIdx)
            continue
        MonitorGetWorkArea(A_Index, &L, &T, &R, &B)
        cx := (L + R) // 2
        cy := (T + B) // 2
        d := 0
        switch direction {
            case "L": if (cx < cCx)
                d := cCx - cx
            case "R": if (cx > cCx)
                d := cx - cCx
            case "U": if (cy < cCy)
                d := cCy - cy
            case "D": if (cy > cCy)
                d := cy - cCy
        }
        if (d > 0 && (bestDist = 0 || d < bestDist)) {
            bestDist := d
            bestIdx := A_Index
        }
    }
    return bestIdx
}

ActMoveMonitorLeft(*)  => MoveToMonitor("L")
ActMoveMonitorRight(*) => MoveToMonitor("R")
ActMoveMonitorUp(*)    => MoveToMonitor("U")
ActMoveMonitorDown(*)  => MoveToMonitor("D")

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
^#+Up::        ActMoveMonitorUp()
^#+Down::      ActMoveMonitorDown()

^#z::          ActUndo()
^#t::          ActToggleAlwaysOnTop()
