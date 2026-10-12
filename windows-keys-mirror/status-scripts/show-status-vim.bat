@echo off
setlocal enabledelayedexpansion

REM Check Vim keymap status
set SCRIPT_DIR=%~dp0
set BASH_SCRIPT=%SCRIPT_DIR%bash-status-vim.sh

for /f "tokens=*" %%A in ('wsl wslpath -a "%BASH_SCRIPT%"') do set BASH_SCRIPT_WSL=%%A

echo Vim Keymap Status:
wsl bash "!BASH_SCRIPT_WSL!"

endlocal
pause
