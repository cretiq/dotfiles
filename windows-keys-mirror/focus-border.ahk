#Requires AutoHotkey v2.0

; Thicker focus border on every monitor. GlazeWM's border is a 1 px DWM frame with no width option, too thin on
; a 7680 px screen. A click-through ring is drawn just outside the focused window
; and over its DWM frame. Ring width is per monitor id: the home monitor (Samsung Odyssey, SAM73D0) gets 4 px, any
; other monitor (office: Samsung LS49A950U, SAM71CE / SAM71CD) 2 px.
; Included by watchers.ahk, which leaves the ring off; run directly it starts the ring.
; The colour follows the Windows light/dark mode: theme-sync.ahk sets focusRingColor.
focusRingColor := "00c8ff"
FocusBorderTick() {
    static g := "", shownKey := "", ringColor := ""
    if !g {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020 +E0x08000000 -DPIScale")
        WinSetTransparent(255, g)
    }
    if (ringColor != focusRingColor) {
        g.BackColor := ringColor := focusRingColor
    }
    r := FocusBorderRect()
    if !r {
        if shownKey {
            g.Hide()
            shownKey := ""
        }
        return
    }
    key := r.ox1 "," r.oy1 "," r.ox2 "," r.oy2 "," r.l "," r.t "," r.r "," r.b
    if (key = shownKey)
        return
    w := r.ox2 - r.ox1, h := r.oy2 - r.oy1
    ; CreateRoundRectRgn takes ellipse diameters and leaves out the right and bottom edge, hence 2 * and + 1.
    outer := DllCall("CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w + 1, "Int", h + 1
        , "Int", 2 * (r.rad + r.thickness), "Int", 2 * (r.rad + r.thickness), "Ptr")
    ; The hole is inset 1 px so the ring also covers GlazeWM's own frame, whose colour it only updates on a focus change.
    hole := DllCall("CreateRoundRectRgn", "Int", r.l - r.ox1 + 1, "Int", r.t - r.oy1 + 1, "Int", r.r - r.ox1, "Int", r.b - r.oy1
        , "Int", 2 * (r.rad - 1), "Int", 2 * (r.rad - 1), "Ptr")
    DllCall("CombineRgn", "Ptr", outer, "Ptr", outer, "Ptr", hole, "Int", 4)  ; RGN_DIFF
    DllCall("DeleteObject", "Ptr", hole)
    DllCall("SetWindowRgn", "Ptr", g.Hwnd, "Ptr", outer, "Int", true)
    g.Show("NA x" r.ox1 " y" r.oy1 " w" w " h" h)
    shownKey := key
}

; The focused window's frame and the ring around it (clipped to its monitor), or "" when no ring is wanted.
FocusBorderRect() {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9, DWMWA_CLOAKED := 14, thicknessById := Map("SAM73D0", 4), defaultThickness := 2
    if !ProcessExist("glazewm.exe")
        return ""
    try {
        hwnd := WinExist("A")
        if (!hwnd || WinGetMinMax(hwnd) = -1 || RegExMatch(WinGetClass(hwnd), "^(Progman|WorkerW|Shell_(Secondary)?TrayWnd)$"))
            return ""
        ; ShellExperienceHost hosts Notification Center, Quick Settings and the calendar flyout; lghub is Logitech G HUB.
        if RegExMatch(WinGetProcessName(hwnd), "i)^(ShellExperienceHost|lghub|ms-teams)\.exe$")
            return ""
        if (SubStr(WinGetTitle(hwnd), 1, 14) = "Administrator:")
            return ""
        cloaked := 0
        DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", DWMWA_CLOAKED, "UInt*", &cloaked, "UInt", 4)
        if cloaked
            return ""

        mi := Buffer(104)  ; MONITORINFOEXW: rcMonitor at 4, szDevice at 40
        NumPut("UInt", 104, mi)
        hmon := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")  ; MONITOR_DEFAULTTONEAREST
        if !DllCall("GetMonitorInfoW", "Ptr", hmon, "Ptr", mi)
            return ""
        dd := Buffer(840)  ; DISPLAY_DEVICEW: DeviceID at 328
        NumPut("UInt", 840, dd)
        DllCall("EnumDisplayDevicesW", "Str", StrGet(mi.Ptr + 40, 32, "UTF-16"), "UInt", 0, "Ptr", dd, "UInt", 1)
        monitorId := StrGet(dd.Ptr + 328, 128, "UTF-16")
        thickness := defaultThickness
        for id, px in thicknessById
            if InStr(monitorId, id)
                thickness := px

        rc := Buffer(16)
        DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", DWMWA_EXTENDED_FRAME_BOUNDS, "Ptr", rc, "UInt", 16)
        l := NumGet(rc, 0, "Int"), t := NumGet(rc, 4, "Int"), r := NumGet(rc, 8, "Int"), b := NumGet(rc, 12, "Int")
        ; Windows 11 rounds window corners at 8 px, scaled by DPI.
        rad := Round(8 * DllCall("GetDpiForWindow", "Ptr", hwnd, "UInt") / 96)
        return {hwnd: hwnd, l: l, t: t, r: r, b: b, rad: rad, thickness: thickness
            , ox1: Max(l - thickness, NumGet(mi, 4, "Int")), oy1: Max(t - thickness, NumGet(mi, 8, "Int"))
            , ox2: Min(r + thickness, NumGet(mi, 12, "Int")), oy2: Min(b + thickness, NumGet(mi, 16, "Int"))}
    } catch
        return ""
}

if (A_LineFile = A_ScriptFullPath) {
    Persistent
    SetTimer(FocusBorderTick, 50)
}
