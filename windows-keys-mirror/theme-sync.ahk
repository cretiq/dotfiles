#Requires AutoHotkey v2.0

; Windows light/dark mode drives these colours:
;   desktop background  light white,     dark black   (only a solid-colour desktop; a picture in Desktop\WallPaper is left alone)
;   focus border        light dark blue, dark cyan    (GlazeWM focused_window border in config.yaml, reloaded while GlazeWM runs; Windows Terminal Glaze theme frame)
;   focus flash         light black,     dark white   (focusFlashColor, drawn by focus-border.ahk)
; Switching the mode is a registry write with no window message, so the value is polled.
; Included by watchers.ahk, which starts ThemeSyncTick; run directly it starts it itself.
ThemeSyncTick() {
    global focusRingColor, focusFlashColor
    static shown := ""
    light := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme", 1)
    if (light = shown)
        return
    shown := light
    focusRingColor := light ? "0a3d91" : "00c8ff"
    focusFlashColor := light ? "000000" : "ffffff"
    SetGlazeBorderColor(focusRingColor)
    if (RegRead("HKCU\Control Panel\Desktop", "WallPaper", "") = "")
        SetDesktopColor(light ? 0xFFFFFF : 0x000000)
}

; Windows Terminal paints its own frame from the Glaze theme and overrides GlazeWM's colour, so both files are set.
SetGlazeBorderColor(hex) {
    glazeChanged := SetHexInFile(EnvGet("USERPROFILE") "\.glzr\glazewm\config.yaml"
        ; The first colour after focused_window > border; other_windows comes later in the file.
        , "(focused_window:[\s\S]*?border:[\s\S]*?color: ')#[0-9a-fA-F]{6}(')", hex)
    SetHexInFile(EnvGet("LOCALAPPDATA") "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        , "(`"name`": `"Glaze`"[\s\S]*?`"frame`": `")#[0-9a-fA-F]{6}(`")", hex)
    if (glazeChanged && ProcessExist("glazewm.exe"))
        Run '"C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe" command wm-reload-config', , "Hide"
}

SetHexInFile(path, pattern, hex) {
    old := FileRead(path, "UTF-8-RAW")
    new := RegExReplace(old, pattern, "$1#" hex "$2", , 1)
    if (new == old)
        return false
    f := FileOpen(path, "w", "UTF-8-RAW")
    f.Write(new)
    f.Close()
    return true
}

SetDesktopColor(rgb) {
    r := (rgb >> 16) & 0xFF, g := (rgb >> 8) & 0xFF, b := rgb & 0xFF
    RegWrite(r " " g " " b, "REG_SZ", "HKCU\Control Panel\Colors", "Background")
    ; SetSysColors takes COLORREF (0x00BBGGRR) and repaints the open session; SPI_SETDESKWALLPAPER with an empty path makes Windows reload the colour.
    elem := Buffer(4), NumPut("Int", 1, elem)  ; COLOR_BACKGROUND
    colour := Buffer(4), NumPut("UInt", (b << 16) | (g << 8) | r, colour)
    DllCall("SetSysColors", "Int", 1, "Ptr", elem, "Ptr", colour)
    DllCall("SystemParametersInfoW", "UInt", 0x14, "UInt", 0, "Str", "", "UInt", 3)  ; SPI_SETDESKWALLPAPER, UPDATEINIFILE | SENDCHANGE
}

if (A_LineFile = A_ScriptFullPath) {
    Persistent
    ThemeSyncTick()
    SetTimer(ThemeSyncTick, 1000)
}
