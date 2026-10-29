#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; Background watchers, started at logon (Startup\watchers.lnk). Live copy: C:\Users\FilipM\Desktop\Keys\watchers.ahk.
; Keys and remaps live in hotkeys-and-remaps.ahk, which toggle scripts edit and reload; these must not restart with it.
; Display and device changes arrive as window messages; the 30 s re-check covers any that are missed.
; The Q10 check is not in it: its WMI query (Win32_PnPEntity, 0.2-0.6 s) runs at start and on device-change messages only.
logFile := EnvGet("LOCALAPPDATA") "\watchers.log"
Log(msg) => FileAppend(FormatTime(, "yyyy-MM-dd HH:mm:ss") "  " msg "`n", logFile)
#Include arrange-windows.ahk
#Include focus-border.ahk
#Include theme-sync.ahk

; Desk mode = the laptop panel is not on the desktop (lid closed, external screen only): GlazeWM on.
; Laptop panel on: GlazeWM off.
; The preset follows the keyboard last typed on: Q10 and Voyager get the Voyager preset (JKLÖ), any other
; keyboard the Standard preset (HJKL). Until a key has been typed, desk mode means Voyager and laptop mode Standard.
; The preset runs only when it changes, so kk/kv/ks overrides last until the next keyboard switch.
; WMI keeps reporting a closed lid's panel as active, so the panel is looked up among the desktop monitors.
glazewmDir := "C:\Program Files\glzr.io\GlazeWM"
setAllKeymap := "/home/filip/.dotfiles/windows-keys/set-all-keymap.sh"
internalPanels := Map()
appliedMode := ""
appliedPreset := ""
pendingPreset := ""
lastKind := ""
deviceKinds := Map()

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

; Timers interrupt each other mid-check: two overlapping checks both saw GlazeWM stopped and both started it
; ("Another instance of the application is already running"). One check at a time; a blocked one retries.
SyncMode() {
    static busy := false
    if busy {
        SetTimer(SyncMode, -2000)
        return
    }
    busy := true
    try ApplyMode()
    finally busy := false
}

ApplyMode() {
    global internalPanels, appliedMode
    if !internalPanels.Count
        internalPanels := InternalPanelIds()
    if (!internalPanels.Count || !MonitorGetCount())
        return
    desk := !PanelOnDesktop()
    running := ProcessExist("glazewm.exe")
    if (desk && !running) {
        ; Waking the laptop briefly drops the panel from the desktop; GlazeWM started then dies with
        ; "Failed to get container to focus". Start it only if desk mode still holds after the monitors settle.
        Sleep 5000
        if (PanelOnDesktop() || !MonitorGetCount()) {
            Log("desk mode not held after settle: GlazeWM start skipped")
            return
        }
        Run '"' glazewmDir '\glazewm.exe"'
    } else if (!desk && running)
        Run '"' glazewmDir '\cli\glazewm.exe" command wm-exit', , "Hide"
    mode := desk ? "desk" : "laptop"
    if (mode = appliedMode)
        return
    leftDesk := (appliedMode = "desk" && !desk)
    appliedMode := mode
    preset := lastKind != "" ? lastKind : desk ? "voyager" : "standard"
    Log(mode " mode: GlazeWM " (desk ? "on" : "off") ", " preset " preset")
    if leftDesk {
        ; wm-exit is asynchronous; moving windows while GlazeWM still runs makes it re-tile them.
        Loop 30 {
            if !ProcessExist("glazewm.exe")
                break
            Sleep 100
        }
        Sleep 500
        Log("arranged windows:`n" ArrangeWindows())
    }
    TrayTip "GlazeWM " (desk ? "on" : "off") ".", desk ? "Desk mode" : "Laptop screen"
    ApplyPreset(preset)
}

; Mode changes and keyboard switches both land here; a call made while set-all-keymap.sh runs is picked up
; by the running call, so two runs never toggle the same files at once.
ApplyPreset(preset) {
    global appliedPreset, pendingPreset
    static busy := false
    pendingPreset := preset
    if busy
        return
    busy := true
    try {
        while (pendingPreset != appliedPreset) {
            appliedPreset := pendingPreset
            hotkeysFile := A_ScriptDir "\hotkeys-and-remaps.ahk"
            before := FileGetTime(hotkeysFile)
            RunWait A_ComSpec ' /c wsl.exe bash ' setAllKeymap ' ' appliedPreset ' --no-reload >> "' logFile '" 2>&1', , "Hide"
            if (FileGetTime(hotkeysFile) != before)
                RestartHotkeys(hotkeysFile)
            Log(appliedPreset " preset applied")
            TrayTip appliedPreset = "voyager" ? "JKLÖ navigation (Voyager preset)." : "HJKL navigation (Standard preset).", "Keyboard"
        }
    } finally busy := false
}

; Q10 (Keychron 0x3434, cable, receiver or Bluetooth) and Voyager (ZSA 0x3297) count as JKLÖ keyboards.
; G HUB's virtual keyboard (mouse-button macros) and the laptop's Fn/hotkey devices say nothing about the hands.
KeyboardKind(hDevice) {
    global deviceKinds
    if deviceKinds.Has(hDevice)
        return deviceKinds[hDevice]
    cch := 0
    DllCall("GetRawInputDeviceInfoW", "Ptr", hDevice, "UInt", 0x20000007, "Ptr", 0, "UInt*", &cch)  ; RIDI_DEVICENAME
    buf := Buffer(cch * 2 + 2, 0)
    DllCall("GetRawInputDeviceInfoW", "Ptr", hDevice, "UInt", 0x20000007, "Ptr", buf, "UInt*", &cch)
    name := StrGet(buf, "UTF-16")
    kind := RegExMatch(name, "i)LGHUB|VID_046D&PID_C232|INTC816|CONVERTEDDEVICE") ? ""
        : RegExMatch(name, "i)VID[_&](02)?(3434|3297)") ? "voyager" : "standard"
    deviceKinds[hDevice] := kind
    Log("keyboard seen: " (kind = "" ? "ignored" : kind) "  " name)
    return kind
}

; WM_INPUT for every key event on any keyboard, also when another window has focus (RIDEV_INPUTSINK).
; Read-only: keys are not blocked or changed. Injected keys (Send) have no device and are skipped.
OnRawInput(wParam, lParam, *) {
    global lastKind
    static header := Buffer(24)  ; RAWINPUTHEADER on x64; hDevice at offset 8
    size := 24
    if (DllCall("GetRawInputData", "Ptr", lParam, "UInt", 0x10000005, "Ptr", header, "UInt*", &size, "UInt", 24, "UInt") = 0xFFFFFFFF)
        return
    hDevice := NumGet(header, 8, "Ptr")
    if !hDevice
        return
    kind := KeyboardKind(hDevice)
    if (kind = "" || kind = lastKind)
        return
    lastKind := kind
    ; Waits out a few keys on the other keyboard; switching back within the delay cancels the change.
    SetTimer(KeyboardSwitched, -1500)
}

KeyboardSwitched() => ApplyPreset(lastKind)

; Restarted from here rather than from the hidden WSL session: a copy launched there did not replace the
; running one (two copies ran, the old remap state won).
RestartHotkeys(path) {
    for p in ComObjGet("winmgmts:").ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name LIKE 'AutoHotkey%'")
        if InStr(p.CommandLine, "hotkeys-and-remaps.ahk")
            ProcessClose(p.ProcessId)
    Run '"' A_AhkPath '" "' path '"'
    Log("restarted hotkeys-and-remaps.ahk")
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
    RunWait A_ComSpec ' /c powershell -NoProfile -ExecutionPolicy Bypass -File "' q10Dir '\q10.ps1" apply -File "' q10Dir '\q10max-win-v2.json" -MaxCells 150 -Yes > "' log '" 2>&1', , "Hide"
    out := FileRead(log)
    if InStr(out, "Verified")
        TrayTip "Windows layout applied.", "Q10 Max"
    else if InStr(out, "already matches")
        TrayTip "Windows layout already set.", "Q10 Max"
    else if (++q10Tries < 3) {
        q10WasPresent := false
        SetTimer(SyncQ10, -30000)
    } else
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

; speaker-guard.ps1 mutes the laptop speaker when the headphones disconnect. It holds a mutex, so a second copy exits at once.
; Found by the remembered PID: a WMI lookup every 30 s stalled this script for 0.3 s and was sometimes cancelled.
speakerPid := 0

SyncSpeakerGuard() {
    global speakerPid
    if (speakerPid && ProcessExist(speakerPid) && ProcessGetName(speakerPid) = "powershell.exe")
        return
    Run 'powershell.exe -MTA -NoProfile -WindowStyle Hidden -File "' A_ScriptDir '\speaker-guard.ps1"', , "Hide", &speakerPid
}

SyncAll() {
    SyncMode()
    SyncSpeakerGuard()
}

rid := Buffer(8 + A_PtrSize, 0)  ; RAWINPUTDEVICE: generic desktop / keyboard, RIDEV_INPUTSINK, this script's window
NumPut("UShort", 1, "UShort", 6, "UInt", 0x100, "Ptr", A_ScriptHwnd, rid)
if !DllCall("RegisterRawInputDevices", "Ptr", rid, "UInt", 1, "UInt", rid.Size)
    Log("raw keyboard input not registered: preset follows the screen only")
OnMessage(0x00FF, OnRawInput)       ; WM_INPUT
OnMessage(0x007E, OnDisplayChange)  ; WM_DISPLAYCHANGE
OnMessage(0x0219, OnDeviceChange)   ; WM_DEVICECHANGE
SyncAll()
SyncQ10()
SetTimer(SyncAll, 30000)
SetTimer(FocusFlashTick, 50)
SetTimer(ThemeSyncTick, 1000)
