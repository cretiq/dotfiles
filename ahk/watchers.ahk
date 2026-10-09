#Requires AutoHotkey v2.0
#SingleInstance Force

; Background watchers, started at logon (Startup\watchers.lnk). Live copy: C:\Users\FilipM\Desktop\Keys\watchers.ahk.
; Keys and remaps live in hotkeys-and-remaps.ahk, which toggle scripts edit and reload; these must not restart with it.

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

SyncGlazewm() {
    running := ProcessExist("glazewm.exe")
    docked := IsDocked()
    if (docked && !running)
        Run '"' glazewmDir '\glazewm.exe"'
    else if (!docked && running)
        Run '"' glazewmDir '\cli\glazewm.exe" command wm-exit', , "Hide"
}

; Block Windows snap shortcuts while GlazeWM is tiling.
#HotIf ProcessExist("glazewm.exe")
#Left::return
#Right::return
#Up::return
#Down::return
#HotIf

; Win+Space is reserved by Windows (input language); forward it to the Command Palette hotkey (Ctrl+Alt+Space; Alt+Space belongs to GlazeWM).
#Space::Send "^!{Space}"

; Keychron Q10 Max: only the cable connection (PID 0x08A1) can be written. The 2.4 GHz receiver (PID 0xD030) is never written to. Pause: create %LOCALAPPDATA%\q10\auto-off.
; q10.ps1 and the keymap are copied to %LOCALAPPDATA%\q10 by `q10 install` (WSL zsh).
q10Dir := EnvGet("LOCALAPPDATA") "\q10"
q10WasPresent := false
q10Tries := 0

Q10Connected() {
    for d in ComObjGet("winmgmts:").ExecQuery("SELECT PNPDeviceID FROM Win32_PnPEntity WHERE PNPDeviceID LIKE 'HID\\VID_3434&PID_08A1%'")
        return true
    return false
}

SyncQ10() {
    global q10WasPresent, q10Tries
    if !Q10Connected() {
        q10WasPresent := false, q10Tries := 0
        return
    }
    if (q10WasPresent || FileExist(q10Dir "\auto-off"))
        return
    q10WasPresent := true
    ; The raw-HID interface enumerates a moment after the keyboard itself.
    Sleep 3000
    log := q10Dir "\auto.log"
    RunWait A_ComSpec ' /c powershell -NoProfile -ExecutionPolicy Bypass -File "' q10Dir '\q10.ps1" apply -File "' q10Dir '\q10max-win-v1.json" -Yes > "' log '" 2>&1', , "Hide"
    out := FileRead(log)
    if InStr(out, "Verified")
        TrayTip "Windows layout applied.", "Q10 Max"
    else if InStr(out, "already matches")
        TrayTip "Windows layout already set.", "Q10 Max"
    else if (++q10Tries < 3)
        q10WasPresent := false
    else
        TrayTip "Could not apply the Windows layout. See " log, "Q10 Max", 3
}

SyncGlazewm()
SetTimer SyncGlazewm, 5000
SyncQ10()
SetTimer SyncQ10, 5000
