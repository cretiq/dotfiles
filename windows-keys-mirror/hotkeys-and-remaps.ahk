#SingleInstance Force

; Install keyboard hook to prevent modifier keys from getting stuck
InstallKeybdHook()

; Reset CapsLock to off on startup/reload
SetCapsLockState "Off"

OpenLocalhost(port, *) => Run('msedge.exe "https://localhost:' port '"')
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

^#!+v::
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

^!#d::SlashCommand "/dev:restart"

^!#n::SlashCommand "/next"

^!#c::SlashCommand "/cut"

^!#r::SlashCommand "/rebuild"

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

<!+d::SlashCommand "/dev:restart"

<!+n::SlashCommand "/next"

<!+c::SlashCommand "/cut"

<!+r::SlashCommand "/rebuild"

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

;---REMAP ESC---
Esc::CapsLock
CapsLock::Esc
;---------------

;---REMAP ALT+HJKL---
!h::Left
!j::Down
!k::Up
!l::Right
!u::^Left
!i::^Right
;---------------------
