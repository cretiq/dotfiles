#Requires AutoHotkey v2.0

; Lays out the open windows per monitor: the frontmost chat-type window takes the right half, the frontmost
; other window the left half, everything else is maximized. With no chat-type window (or only chat-type ones)
; everything is maximized. Included by watchers.ahk; run directly (`/dry` = plan only) to print the layout.
; Windows without a maximize box, owned windows, tool windows, cloaked (other desktop) and minimized windows are left alone.
ArrangeWindows(dry := false) {
    static GW_OWNER := 4, DWMWA_CLOAKED := 14, WS_MAXIMIZEBOX := 0x10000, WS_EX_TOOLWINDOW := 0x80
    static sideRx := "i)^(ms-teams|ChatGPT|Claude|Slack|Discord|Spotify|keymapp)\.exe$"
    static skipRx := "i)^(TextInputHost|PowerToys.*|Convey)\.exe$"

    monitors := Map()
    for hwnd in WinGetList() {
        try {
            exe := WinGetProcessName(hwnd)
            cloaked := 0
            DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", DWMWA_CLOAKED, "UInt*", &cloaked, "UInt", 4)
            if (WinGetTitle(hwnd) = "" || cloaked || WinGetMinMax(hwnd) = -1 || RegExMatch(exe, skipRx)
                || !(WinGetStyle(hwnd) & WS_MAXIMIZEBOX) || (WinGetExStyle(hwnd) & WS_EX_TOOLWINDOW)
                || DllCall("GetWindow", "Ptr", hwnd, "UInt", GW_OWNER, "Ptr"))
                continue
            WinGetPos(&x, &y, &w, &h, hwnd)
            mon := MonitorGetPrimary()
            Loop MonitorGetCount() {
                MonitorGet(A_Index, &ml, &mt, &mr, &mb)
                if (x + w // 2 >= ml && x + w // 2 < mr && y + h // 2 >= mt && y + h // 2 < mb)
                    mon := A_Index
            }
            if !monitors.Has(mon)
                monitors[mon] := []
            monitors[mon].Push({hwnd: hwnd, exe: exe, title: WinGetTitle(hwnd), side: !!RegExMatch(exe, sideRx)})
        }
    }

    plan := ""
    for mon, wins in monitors {
        MonitorGetWorkArea(mon, &l, &t, &r, &b)
        side := main := ""
        for win in wins {
            if (win.side && !side)
                side := win
            else if (!win.side && !main)
                main := win
        }
        split := side && main
        mid := (l + r) // 2
        for win in wins {
            if (split && win = main)
                role := "left", box := [l, t, mid, b]
            else if (split && win = side)
                role := "right", box := [mid, t, r, b]
            else
                role := "max", box := ""
            plan .= "monitor " mon ": " role "  " win.exe "  " SubStr(win.title, 1, 50) "`n"
            if dry
                continue
            try {
                if box
                    Place(win.hwnd, box*)
                else
                    WinMaximize(win.hwnd)
            } catch
                plan .= "  failed (elevated window?)`n"
        }
        if (!dry && split) {
            try WinMoveTop(main.hwnd)
            try WinMoveTop(side.hwnd)
        }
    }
    return plan
}

; Window frames carry an invisible border (shadow) that DwmGetWindowAttribute(EXTENDED_FRAME_BOUNDS) excludes; compensate so the visible edges meet.
Place(hwnd, l, t, r, b) {
    WinRestore(hwnd)
    WinGetPos(&x, &y, &w, &h, hwnd)
    rect := Buffer(16)
    DllCall("dwmapi\DwmGetWindowAttribute", "Ptr", hwnd, "UInt", 9, "Ptr", rect, "UInt", 16)
    dl := NumGet(rect, 0, "Int") - x
    dt := NumGet(rect, 4, "Int") - y
    dr := x + w - NumGet(rect, 8, "Int")
    db := y + h - NumGet(rect, 12, "Int")
    WinMove(l - dl, t - dt, r - l + dl + dr, b - t + dt + db, hwnd)
}

if (A_LineFile = A_ScriptFullPath)
    FileAppend(ArrangeWindows(A_Args.Length && A_Args[1] = "/dry"), "*")
