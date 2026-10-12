@echo off
setlocal enabledelayedexpansion

REM Check ESC/CapsLock remap status
set SCRIPT_DIR=%~dp0
set AHK_FILE=%SCRIPT_DIR%..\hotkeys-and-remaps.ahk
set BASH_SCRIPT=%SCRIPT_DIR%bash-status-esc.sh

for /f "tokens=*" %%A in ('wsl wslpath -a "%BASH_SCRIPT%"') do set BASH_SCRIPT_WSL=%%A
for /f "tokens=*" %%A in ('wsl wslpath -a "%AHK_FILE%"') do set AHK_FILE_WSL=%%A

echo ESC/CapsLock Status:
wsl bash "!BASH_SCRIPT_WSL!" "!AHK_FILE_WSL!"

endlocal
pause
