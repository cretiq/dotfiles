#SingleInstance Force

; Install keyboard hook to prevent modifier keys from getting stuck
InstallKeybdHook()

; Reset CapsLock to off on startup/reload
SetCapsLockState "Off"

OpenLocalhost(port, *) => Run('firefox.exe "https://localhost:' port '"')
; Left-only: AltGr is seen as Ctrl+Alt, so plain ^! would swallow @ £ $ € (AltGr+2..5) on the Swedish layout.
Loop 6
    Hotkey "<^<!" A_Index, OpenLocalhost.Bind(5170 + A_Index)

ToggleTheme() {
    key := "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    next := RegRead(key, "AppsUseLightTheme") = 0 ? 1 : 0
    RegWrite(next, "REG_DWORD", key, "AppsUseLightTheme")
    RegWrite(next, "REG_DWORD", key, "SystemUsesLightTheme")
    DllCall("SendMessageTimeout", "Ptr", 0xFFFF, "UInt", 0x1A, "Ptr", 0, "Str", "ImmersiveColorSet", "UInt", 2, "UInt", 5000, "Ptr", 0)
}

^#!+8::ToggleTheme()

; Keeps the PC awake and Teams Available. The execution state covers sleep and display-off; the lock (machine inactivity limit) and Teams Away follow input idle, so F15 (bound to nothing) goes out every minute. Reload turns it off.
KeepAwake := false
A_TrayMenu.Add("Keep awake", (*) => ToggleKeepAwake())

KeepAwakeNudge() => Send("{F15}")

ToggleKeepAwake() {
    global KeepAwake := !KeepAwake
    DllCall("SetThreadExecutionState", "UInt", KeepAwake ? 0x80000003 : 0x80000000)
    SetTimer(KeepAwakeNudge, KeepAwake ? 60000 : 0)
    state := KeepAwake ? "on" : "off"
    KeepAwake ? A_TrayMenu.Check("Keep awake") : A_TrayMenu.Uncheck("Keep awake")
    A_IconTip := "Keep awake " state
    TrayTip("Keep awake " state, "hotkeys-and-remaps.ahk")
}

^#!+7::ToggleKeepAwake()

^#!+a::
{
    if WinExist("ahk_exe Spotify.exe")
        WinActivate
    else
        Run "spotify:"
}

^#!+r::
{
    if WinExist("ahk_exe devenv.exe")
        WinActivate
    else
    {
        vsPath := "C:\Program Files\Microsoft Visual Studio\18\Insiders\Common7\IDE\devenv.exe"

        if FileExist(vsPath)
            Run vsPath
    }
}

^#!+d::
{
    if WinExist("ahk_exe WindowsTerminal.exe")
        WinActivate
    else
        Run "wt"
}

^#!+c::
{
    if WinExist("ahk_exe msedge.exe")
        WinActivate
    else
    {
        msEdgePath := "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

        if FileExist(msEdgePath)
            Run '"' msEdgePath '" --profile-directory="Profile 1"'
    }
}

toastCur := ""

GdipStart() {
    static token := 0
    if token
        return
    input := Buffer(24, 0)
    NumPut("UInt", 1, input)
    DllCall("gdiplus\GdiplusStartup", "Ptr*", &token, "Ptr", input, "Ptr", 0)
}

; A GDI+ canvas (transparent 32-bit bitmap) of the given size; returns its graphics and sets bmp.
GdipCanvas(w, h, &bmp) {
    bmp := 0, g := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", w, "Int", h, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &bmp)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", bmp, "Ptr*", &g)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", g, "Int", 4)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", g, "Int", 4)
    DllCall("gdiplus\GdipSetInterpolationMode", "Ptr", g, "Int", 7)
    return g
}

; Pill outline: two half-circle arcs of diameter h joined by straight edges.
GdipPill(x, y, w, h) {
    path := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &path)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y, "Float", h, "Float", h, "Float", 90, "Float", 180)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - h, "Float", y, "Float", h, "Float", h, "Float", 270, "Float", 180)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", path)
    return path
}

GdipFill(g, argb, path) {
    brush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", argb, "Ptr*", &brush)
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", brush, "Ptr", path)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", brush)
}

; Draws the whole glass pill once, with its shadow margin, into a cached bitmap. The screen behind it is captured, shrunk 6x
; and stretched back for the blur; that shrink factor is the blur strength.
ToastRender(text, scale, l, t, r, b) {
    GdipStart()
    family := font := format := 0
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI Semibold", "Ptr", 0, "Ptr*", &family)
    DllCall("gdiplus\GdipCreateFont", "Ptr", family, "Float", Round(16 * scale), "Int", 0, "Int", 2, "Ptr*", &font)
    DllCall("gdiplus\GdipCreateStringFormat", "Int", 0, "Int", 0, "Ptr*", &format)
    DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", format, "Int", 1)
    DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", format, "Int", 1)
    probe := GdipCanvas(1, 1, &probeBmp)
    box := Buffer(16, 0), size := Buffer(16, 0)
    NumPut("Float", 10000, box, 8), NumPut("Float", 10000, box, 12)
    DllCall("gdiplus\GdipMeasureString", "Ptr", probe, "WStr", text, "Int", -1, "Ptr", font, "Ptr", box, "Ptr", format, "Ptr", size, "Ptr", 0, "Ptr", 0)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", probe)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", probeBmp)
    h := Round(NumGet(size, 12, "Float") + 18 * scale)
    w := Round(NumGet(size, 8, "Float") + 32 * scale)
    m := Round(26 * scale)
    cw := w + 2 * m, ch := h + 2 * m
    px := (l + r - w) // 2, py := b - h - (b - t) // 8

    g := GdipCanvas(cw, ch, &bmp)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", g, "UInt", 0)
    pill := GdipPill(m, m, w, h)

    step := Max(1, Round(2.2 * scale)), drop := Round(5 * scale)
    Loop 8 {
        grow := (9 - A_Index) * step
        layer := GdipPill(m - grow, m - grow + drop, w + 2 * grow, h + 2 * grow)
        GdipFill(g, 0x10000000, layer)
        DllCall("gdiplus\GdipDeletePath", "Ptr", layer)
    }

    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdcFull := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    hbmFull := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", w, "Int", h, "Ptr")
    DllCall("SelectObject", "Ptr", hdcFull, "Ptr", hbmFull)
    DllCall("BitBlt", "Ptr", hdcFull, "Int", 0, "Int", 0, "Int", w, "Int", h, "Ptr", hdcScreen, "Int", px, "Int", py, "UInt", 0x40CC0020)
    sw := Max(1, w // 6), sh := Max(1, h // 6)
    hdcSmall := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    hbmSmall := DllCall("CreateCompatibleBitmap", "Ptr", hdcScreen, "Int", sw, "Int", sh, "Ptr")
    DllCall("SelectObject", "Ptr", hdcSmall, "Ptr", hbmSmall)
    DllCall("SetStretchBltMode", "Ptr", hdcSmall, "Int", 4)
    DllCall("StretchBlt", "Ptr", hdcSmall, "Int", 0, "Int", 0, "Int", sw, "Int", sh, "Ptr", hdcFull, "Int", 0, "Int", 0, "Int", w, "Int", h, "UInt", 0xCC0020)
    small := 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hbmSmall, "Ptr", 0, "Ptr*", &small)
    ; The blur is stretched back to full size and painted into the pill outline as a texture: a clip path has hard,
    ; stair-stepped edges, a filled outline is anti-aliased.
    stretch := GdipCanvas(w, h, &stretchBmp)
    DllCall("gdiplus\GdipDrawImageRectI", "Ptr", stretch, "Ptr", small, "Int", 0, "Int", 0, "Int", w, "Int", h)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", stretch)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", small)
    texture := 0
    DllCall("gdiplus\GdipCreateTexture", "Ptr", stretchBmp, "Int", 4, "Ptr*", &texture)
    DllCall("gdiplus\GdipTranslateTextureTransform", "Ptr", texture, "Float", m, "Float", m, "Int", 0)
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", texture, "Ptr", pill)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", texture)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", stretchBmp)
    DllCall("DeleteDC", "Ptr", hdcSmall), DllCall("DeleteDC", "Ptr", hdcFull)
    DllCall("DeleteObject", "Ptr", hbmSmall), DllCall("DeleteObject", "Ptr", hbmFull)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)

    GdipFill(g, 0x300C1016, pill)
    GdipFill(g, 0x10FFFFFF, pill)
    rect := Buffer(16)
    NumPut("Int", m, rect, 0), NumPut("Int", m, rect, 4), NumPut("Int", w, rect, 8), NumPut("Int", h, rect, 12)
    sheen := rimBrush := pen := 0
    DllCall("gdiplus\GdipCreateLineBrushFromRectI", "Ptr", rect, "UInt", 0x18FFFFFF, "UInt", 0x00FFFFFF, "Int", 1, "Int", 0, "Ptr*", &sheen)
    DllCall("gdiplus\GdipFillPath", "Ptr", g, "Ptr", sheen, "Ptr", pill)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", sheen)

    DllCall("gdiplus\GdipCreateLineBrushFromRectI", "Ptr", rect, "UInt", 0xB8FFFFFF, "UInt", 0x28FFFFFF, "Int", 2, "Int", 0, "Ptr*", &rimBrush)
    DllCall("gdiplus\GdipCreatePen2", "Ptr", rimBrush, "Float", Max(1.2, 1.3 * scale), "Int", 2, "Ptr*", &pen)
    rim := GdipPill(m + 0.7, m + 0.7, w - 1.4, h - 1.4)
    DllCall("gdiplus\GdipDrawPath", "Ptr", g, "Ptr", pen, "Ptr", rim)
    DllCall("gdiplus\GdipDeletePath", "Ptr", rim)
    DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", rimBrush)

    layout := Buffer(16, 0)
    NumPut("Float", m, layout, 0), NumPut("Float", m + Max(1, scale), layout, 4), NumPut("Float", w, layout, 8), NumPut("Float", h, layout, 12)
    textBrush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0x40000000, "Ptr*", &textBrush)
    DllCall("gdiplus\GdipDrawString", "Ptr", g, "WStr", text, "Int", -1, "Ptr", font, "Ptr", layout, "Ptr", format, "Ptr", textBrush)
    DllCall("gdiplus\GdipSetSolidFillColor", "Ptr", textBrush, "UInt", 0xF5FFFFFF)
    NumPut("Float", m, layout, 4)
    DllCall("gdiplus\GdipDrawString", "Ptr", g, "WStr", text, "Int", -1, "Ptr", font, "Ptr", layout, "Ptr", format, "Ptr", textBrush)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", textBrush)

    DllCall("gdiplus\GdipDeletePath", "Ptr", pill)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
    DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", format)
    DllCall("gdiplus\GdipDeleteFont", "Ptr", font)
    DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", family)
    return {bmp: bmp, cw: cw, ch: ch, x: px - m, y: py - m}
}

; Pushes the cached pill to the screen at scale s and opacity alpha (0-255).
ToastFrame(s, alpha) {
    global toastCur
    g := GdipCanvas(toastCur.cw, toastCur.ch, &frame)
    DllCall("gdiplus\GdipSetCompositingMode", "Ptr", g, "Int", 1)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", g, "Int", 4)
    dw := toastCur.cw * s, dh := toastCur.ch * s
    DllCall("gdiplus\GdipDrawImageRect", "Ptr", g, "Ptr", toastCur.bmp, "Float", (toastCur.cw - dw) / 2, "Float", (toastCur.ch - dh) / 2, "Float", dw, "Float", dh)
    hbm := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", frame, "Ptr*", &hbm, "UInt", 0)
    hdcScreen := DllCall("GetDC", "Ptr", 0, "Ptr")
    hdc := DllCall("CreateCompatibleDC", "Ptr", hdcScreen, "Ptr")
    DllCall("SelectObject", "Ptr", hdc, "Ptr", hbm)
    pos := Buffer(8), size := Buffer(8), src := Buffer(8, 0), blend := Buffer(4, 0)
    NumPut("Int", toastCur.x, pos, 0), NumPut("Int", toastCur.y, pos, 4)
    NumPut("Int", toastCur.cw, size, 0), NumPut("Int", toastCur.ch, size, 4)
    NumPut("UChar", alpha, blend, 2), NumPut("UChar", 1, blend, 3)
    DllCall("UpdateLayeredWindow", "Ptr", toastCur.window.Hwnd, "Ptr", hdcScreen, "Ptr", pos, "Ptr", size, "Ptr", hdc, "Ptr", src, "UInt", 0, "Ptr", blend, "UInt", 2)
    DllCall("DeleteDC", "Ptr", hdc)
    DllCall("DeleteObject", "Ptr", hbm)
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdcScreen)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", g)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", frame)
}

; Milliseconds from the performance counter: A_TickCount only moves in ~15 ms steps, which makes an animation judder.
ToastNow() {
    static freq := 0
    if !freq
        DllCall("QueryPerformanceFrequency", "Int64*", &freq)
    count := 0
    DllCall("QueryPerformanceCounter", "Int64*", &count)
    return count * 1000 / freq
}

; 1 ms timer resolution only while an animation runs: at the default the frames come ~24 ms apart with 31 ms hitches, with it ~16 ms.
ToastPeriod(on) {
    static active := false
    if (on = active)
        return
    DllCall(on ? "winmm\timeBeginPeriod" : "winmm\timeEndPeriod", "UInt", 1)
    active := on
}

ToastTick() {
    global toastCur
    if !toastCur
        return
    entering := toastCur.phase = "in"
    t := Min(1, (ToastNow() - toastCur.t0) / (entering ? 240 : 200))
    e := t < 0.5 ? 4 * t ** 3 : 1 - (2 - 2 * t) ** 3 / 2
    if entering {
        ToastFrame(0.88 + 0.12 * e, Round(255 * e))
        if (t >= 1) {
            SetTimer(ToastTick, 0)
            ToastPeriod(false)
        }
    } else {
        ToastFrame(1 - 0.06 * e, Round(255 * (1 - e)))
        if (t >= 1)
            ToastDestroy()
    }
}

ToastOut() {
    global toastCur
    if toastCur {
        toastCur.phase := "out", toastCur.t0 := ToastNow()
        ToastPeriod(true)
        SetTimer(ToastTick, 8)
    }
}

ToastDestroy() {
    global toastCur
    SetTimer(ToastTick, 0), SetTimer(ToastOut, 0)
    ToastPeriod(false)
    if toastCur {
        toastCur.window.Destroy()
        DllCall("gdiplus\GdipDisposeImage", "Ptr", toastCur.bmp)
        toastCur := ""
    }
}

; A click-through glass pill at the top centre of the monitor under the cursor. A message replaces the one on screen
; without animating in again. Nothing runs while no message is shown.
Toast(text, ms) {
    global toastCur
    animate := !toastCur
    ToastDestroy()
    MouseGetPos(&mx, &my)
    Loop MonitorGetCount() {
        MonitorGet(A_Index, &l, &t, &r, &b)
        if (mx >= l && mx < r && my >= t && my < b)
            break
    }
    look := ToastRender(text, A_ScreenDPI / 96, l, t, r, b)
    window := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x80020 +E0x08000000 -DPIScale")
    window.Show("Hide")
    toastCur := {window: window, bmp: look.bmp, cw: look.cw, ch: look.ch, x: look.x, y: look.y, phase: "in", t0: ToastNow()}
    ToastFrame(animate ? 0.88 : 1, animate ? 0 : 255)
    DllCall("ShowWindow", "Ptr", window.Hwnd, "Int", 8)
    if animate {
        ToastPeriod(true)
        SetTimer(ToastTick, 8)
    }
    SetTimer(ToastOut, -ms)
}

; audio-tray (C:\Dev\Own\audio-tray) owns Ctrl+Alt+Shift+Win+1 / +2 (connect / disconnect AirPods) and broadcasts one of
; these codes for every output change and key press (its Notice enum). Only the wording and the pill live here.
AudioTrayToast(code, *) {
    static texts := Map(1, "AirPods connected", 2, "AirPods disconnected", 3, "AirPods active", 4, "Speakers active"
        , 5, "Connecting to AirPods...", 6, "Disconnecting AirPods...", 7, "AirPods not found"
        , 8, "Could not switch output", 9, "AirPods hotkeys unavailable")
    if texts.Has(code)
        Toast(texts[code], 2000)
}

OnMessage(DllCall("RegisterWindowMessage", "Str", "audio-tray-toast", "UInt"), AudioTrayToast)

^#!+e::
{
    if WinExist("ahk_exe Obsidian.exe")
        WinActivate
    else
    {
        obsidianPath := "C:\Users\" A_UserName "\AppData\Local\Programs\Obsidian\Obsidian.exe"

        if FileExist(obsidianPath)
            Run obsidianPath ' --disable-smooth-scrolling'
    }
}

^#!+f::
{
    if WinExist("ahk_class CabinetWClass")
        WinActivate
    else
        Run A_MyDocuments
}

^#!+s::
{
    beekeeperPath := "C:\Users\" A_UserName "\AppData\Local\Programs\Beekeeper Studio\Beekeeper Studio.exe"

    if WinExist("ahk_exe Beekeeper Studio.exe")
        WinActivate
    else if FileExist(beekeeperPath)
        Run beekeeperPath
}

^#!+h::
{
    if WinExist("ahk_exe claude.exe")
        WinActivate
    else
        Run "explorer.exe shell:AppsFolder\Claude_pzs8sxrjxfjjc!Claude"
}

^#!+j::
{
    if WinExist("ahk_exe ChatGPT.exe")
        WinActivate
    else
        Run "explorer.exe shell:AppsFolder\OpenAI.Codex_2p2nqsd0c76g0!App"
}

^#!+b::
{
    if WinExist("ahk_exe rider64.exe")
        WinActivate
    else
    {
        gkPath := "C:\Users\FilipM\AppData\Local\Programs\Rider\bin\rider64.exe"

        if FileExist(gkPath)
            Run gkPath
    }
}

^#!+t::
{
    if WinExist("ahk_exe ms-teams.exe")
        WinActivate
    else
        Run "ms-teams:"
}

^#!+k::
{
    if WinExist("ahk_exe keymapp.exe")
        WinActivate
    else
    {
        keymappPath := "C:\Program Files (x86)\Keymapp\keymapp.exe"

        if FileExist(keymappPath)
            Run keymappPath
    }
}

^#!+y::
{
    if WinExist("Administrator: ahk_exe powershell.exe")
        WinActivate
    else
        Run '*RunAs powershell.exe', "C:\"
}

^!+y::
{
    if WinExist("Administrator: ahk_exe powershell.exe")
    {
        FileAppend "", EnvGet("USERPROFILE") "\.m5kick-trigger"
        WinActivate
    }
    else
        Run '*RunAs powershell.exe -NoExit -Command m5kick', "C:\"
}

+#!^0::Reload

^#!+9::
{
    Run "wt wsl bash /home/filip/.dotfiles/windows-keys/interactive-menu-toggle-remaps.sh"
}

^#!+6::
{
    Run 'powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\' A_UserName '\Desktop\Keys\restart-window-switcher.ps1"', , "Hide"
}

CaptureToTerminal(workflow, timeout)
{
    KeyWait "Ctrl"
    KeyWait "Alt"
    KeyWait "Shift"
    A_Clipboard := ""
    Run '"' EnvGet("LOCALAPPDATA") '\Programs\ShareX\ShareX.exe" -workflow ' workflow
    if !ClipWait(timeout, 1)
        return

    if WinExist("ahk_exe WindowsTerminal.exe")
    {
        WinActivate
        if WinWaitActive(, , 2)
            Send "^v"
    }
}

ShareX(args)
{
    KeyWait "Ctrl"
    KeyWait "Shift"
    Run '"' EnvGet("LOCALAPPDATA") '\Programs\ShareX\ShareX.exe" ' args
}

<^<!q::CaptureToTerminal "ActiveWindowPlain", 5

<^<!w::CaptureToTerminal "RegionPlain", 30


; Chords from the Q10's left space layer and the Voyager's layer 7 (Ctrl+Alt+Win). The keys are held when the hotkey fires, so wait for release before typing.
SlashCommand(name, submit := true)
{
    KeyWait "Ctrl"
    KeyWait "Alt"
    KeyWait "Shift"
    KeyWait "LWin"
    KeyWait "RWin"
    SendText name
    Sleep 20
    Send "{Space}"
    if submit
    {
        Sleep 100
        Send "{Enter}"
    }
}

^!#d::SlashCommand "/restart"

^!#n::SlashCommand "/next"

^!#x::SlashCommand "/cut"

^!#r::SlashCommand "/rebuild"

^!#c::SlashCommand "/copy"

^!#o::SlashCommand "/git:commit-detailed-push"

^!#h::SlashCommand "/how-to-test"

^!#z::
{
    SlashCommand "/generate:long-title"
    Sleep 300
    SlashCommand "/copy"
    Sleep 300
    SlashCommand "/rename", false
}

; Laptop keyboard: no Win-layer chords there. Active while GlazeWM is off (watchers.ahk keeps it off with the laptop screen on, and Alt+Shift+key belongs to GlazeWM otherwise).
; The /generate:long-title, /copy, /rename macro is repeated below rather than shared: scripts/bindings.py reads it from the z chord block above.
#HotIf !ProcessExist("glazewm.exe")
; Ctrl+Shift+1-5 stand in for the ShareX keys on Ctrl+Alt Q W E R T (the last three are ShareX's own hotkeys, all default task settings).
^+1::CaptureToTerminal "ActiveWindowPlain", 5

^+2::CaptureToTerminal "RegionPlain", 30

^+3::ShareX "-ActiveWindow"

^+4::ShareX "-RectangleRegion"

^+5::ShareX "-OpenImageHistory"

<!+d::SlashCommand "/restart"

<!+n::SlashCommand "/next"

<!+x::SlashCommand "/cut"

<!+r::SlashCommand "/rebuild"

<!+c::SlashCommand "/copy"

<!+o::SlashCommand "/git:commit-detailed-push"

<!+h::SlashCommand "/how-to-test"

<!+z::
{
    SlashCommand "/generate:long-title"
    Sleep 300
    SlashCommand "/copy"
    Sleep 300
    SlashCommand "/rename", false
}
#HotIf

; Laptop only (GlazeWM off): Alt+S / Alt+D = previous / next tab in any app (Ctrl+Shift+Tab / Ctrl+Tab). Windows Terminal has its own Alt+S/D bindings; dialogs (#32770) keep their Alt+letter button shortcuts.
#HotIf !ProcessExist("glazewm.exe") && !WinActive("ahk_exe WindowsTerminal.exe") && !WinActive("ahk_class #32770")
<!s::Send "^+{Tab}"

<!d::Send "^{Tab}"
#HotIf

; Laptop mode is GlazeWM stopped (watchers.ahk); desk mode keeps Ctrl+Shift+6 free.
#HotIf !ProcessExist("glazewm.exe")
^+6::Run '"' EnvGet("LOCALAPPDATA") '\Programs\ShareX\ShareX.exe" -ScrollingCapture'
#HotIf

;---REMAP ESC---
;Esc::CapsLock
;CapsLock::Esc
;---------------

;---REMAP ALT+HJKL---
;!h::Left
;!j::Down
;!k::Up
;!l::Right
;!u::^Left
;!i::^Right
;---------------------
