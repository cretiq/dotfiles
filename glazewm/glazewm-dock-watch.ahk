#SingleInstance Force

; GlazeWM only runs while a wide external display (docked) is connected.
; Laptop panel alone is < 2500 px wide even before DPI scaling is undone.
glazewmDir := "C:\Program Files\glzr.io\GlazeWM"
dockedMinWidth := 2500

IsDocked() {
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &left, , &right)
        if (right - left >= dockedMinWidth)
            return true
    }
    return false
}

Sync() {
    running := ProcessExist("glazewm.exe")
    docked := IsDocked()
    if (docked && !running)
        Run '"' glazewmDir '\glazewm.exe"'
    else if (!docked && running)
        Run '"' glazewmDir '\cli\glazewm.exe" command wm-exit', , "Hide"
}

Sync()
SetTimer Sync, 5000

; Block Windows snap shortcuts while GlazeWM is tiling.
#HotIf ProcessExist("glazewm.exe")
#Left::return
#Right::return
#Up::return
#Down::return
#HotIf

; Win+Space is reserved by Windows (input language); forward it to the Command Palette hotkey (Ctrl+Alt+Space; Alt+Space belongs to GlazeWM).
#Space::Send "^!{Space}"
