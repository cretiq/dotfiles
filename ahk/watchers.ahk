#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Background watchers, started at logon (Startup\watchers.lnk). Live copy: C:\Users\FilipM\Desktop\Keys\watchers.ahk.
; Keys and remaps live in hotkeys-and-remaps.ahk, which toggle scripts edit and reload; these must not restart with it.
; Display and device changes arrive as window messages; the 30 s re-check covers any that are missed.
logFile := EnvGet("LOCALAPPDATA") "\watchers.log"
Log(msg) => FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " msg "`n", logFile)

; Desk mode = the laptop panel is not on the desktop (lid closed, external screen only): GlazeWM on and the
; Voyager preset, whose remaps are off so Alt+HJKL reaches GlazeWM. Laptop panel on: GlazeWM off, Standard preset.
; The preset is applied only when the mode changes, so kk/kv/ks overrides last until the next change.
; WMI keeps reporting a closed lid's panel as active, so the panel is looked up among the desktop monitors.
glazewmDir := "C:\Program Files\glzr.io\GlazeWM"
setAllKeymap := "/home/filip/.dotfiles/windows-keys/set-all-keymap.sh"
internalPanels := Map()
appliedMode := ""

InternalPanelIds() {
    ids := Map()
    for m in ComObjGet("winmgmts:root\wmi").ExecQuery("SELECT InstanceName, VideoOutputTechnology FROM WmiMonitorConnectionParams") {
        tech := m.VideoOutputTechnology & 0xFFFFFFFF
        ; D3DKMDT_VOT_INTERNAL, DISPLAYPORT_EMBEDDED, UDI_EMBEDDED
        if (tech = 0x80000000 || tech = 11 || tech = 13)
            ids[StrUpper(RegExReplace(m.InstanceName, "i)^DISPLAY\\|_\d+$"))] := true
    }
    return ids
}

PanelOnDesktop() {
    dd := Buffer(840)  ; DISPLAY_DEVICEW: StateFlags at 324, DeviceID at 328
    Loop MonitorGetCount() {
        adapter := MonitorGetName(A_Index)
        i := 0
        Loop {
            NumPut("UInt", 840, dd)
            if !DllCall("EnumDisplayDevicesW", "Str", adapter, "UInt", i++, "Ptr", dd, "UInt", 1)
                break
            if (NumGet(dd, 324, "UInt") & 1)
                && RegExMatch(StrGet(dd.Ptr + 328, 128, "UTF-16"), "i)DISPLAY#([^#]+#[^#]+)#", &m)
                && internalPanels.Has(StrUpper(StrReplace(m[1], "#", "\")))
                return true
        }
    }
    return false
}

SyncMode() {
    global internalPanels, appliedMode
    if !internalPanels.Count
        internalPanels := InternalPanelIds()
    if (!internalPanels.Count || !MonitorGetCount())
        return
    desk := !PanelOnDesktop()
    running := ProcessExist("glazewm.exe")
    if (desk && !running)
        Run '"' glazewmDir '\glazewm.exe"'
    else if (!desk && running)
        Run '"' glazewmDir '\cli\glazewm.exe" command wm-exit', , "Hide"
    mode := desk ? "desk" : "laptop"
    if (mode = appliedMode)
        return
    appliedMode := mode
    preset := desk ? "voyager" : "standard"
    Log(mode " mode: GlazeWM " (desk ? "on" : "off") ", " preset " preset")
    Run A_ComSpec ' /c wsl.exe bash ' setAllKeymap ' ' preset ' >> "' logFile '" 2>&1', , "Hide"
    TrayTip desk ? "GlazeWM on, Voyager preset." : "GlazeWM off, Standard preset.", desk ? "Desk mode" : "Laptop screen"
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
    RunWait A_ComSpec ' /c powershell -NoProfile -ExecutionPolicy Bypass -File "' q10Dir '\q10.ps1" apply -File "' q10Dir '\q10max-win-v2.json" -Yes > "' log '" 2>&1', , "Hide"
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

; Monitor setups and USB devices settle over a few seconds; each new message restarts the delay.
OnDisplayChange(*) {
    SetTimer(SyncMode, -3000)
}

OnDeviceChange(wParam, *) {
    if (wParam = 0x0007)  ; DBT_DEVNODES_CHANGED
        SetTimer(SyncQ10, -2000)
}

SyncAll() {
    SyncMode()
    SyncQ10()
}

OnMessage(0x007E, OnDisplayChange)  ; WM_DISPLAYCHANGE
OnMessage(0x0219, OnDeviceChange)   ; WM_DEVICECHANGE
SyncAll()
SetTimer(SyncAll, 30000)
