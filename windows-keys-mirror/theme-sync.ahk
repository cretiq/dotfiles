#Requires AutoHotkey v2.0

; Windows light/dark mode drives two colours:
;   desktop background  light white,     dark black   (only a solid-colour desktop; a picture in Desktop\WallPaper is left alone)
;   focus ring          light dark blue, dark cyan    (focusRingColor, drawn by focus-border.ahk)
; Switching the mode is a registry write with no window message, so the value is polled.
; Included by watchers.ahk, which starts ThemeSyncTick; run directly it starts it itself.
ThemeSyncTick() {
    global focusRingColor
    static shown := ""
    light := RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize", "SystemUsesLightTheme", 1)
    if (light = shown)
        return
    shown := light
    focusRingColor := light ? "0a3d91" : "00c8ff"
    if (RegRead("HKCU\Control Panel\Desktop", "WallPaper", "") = "")
        SetDesktopColor(light ? 0xFFFFFF : 0x000000)
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
