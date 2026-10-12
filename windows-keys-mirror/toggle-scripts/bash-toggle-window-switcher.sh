#!/bin/bash

# Toggle window-switcher [switch-windows] hotkey between Voyager (win+g) and Standard (alt+§)
# Usage: ./bash-toggle-window-switcher.sh [ini_file_path]

INI_FILE="${1:-/mnt/c/Users/FilipM/AppData/Local/Programs/window-switcher/window-switcher.ini}"

if [ ! -f "$INI_FILE" ]; then
    echo "Error: File not found at $INI_FILE"
    exit 1
fi

TEMP_FILE="${INI_FILE}.tmp"

# Check current hotkey under [switch-windows]
if awk '/^\[switch-windows\]/{f=1} f && /^hotkey/{print; exit}' "$INI_FILE" | grep -q "win+g"; then
    # Currently Voyager → switch to Standard
    python3 -c "
ini_file = '$INI_FILE'
with open(ini_file, 'r') as f:
    lines = f.readlines()
in_section = False
for i, line in enumerate(lines):
    if '[switch-windows]' in line:
        in_section = True
    elif line.startswith('['):
        in_section = False
    if in_section and 'hotkey = win+g' in line:
        lines[i] = 'hotkey = alt+§\n'
        break
with open(ini_file, 'w') as f:
    f.writelines(lines)
"
    echo "Window Switcher: Voyager → Standard (alt+§)"
else
    # Currently Standard → switch to Voyager
    python3 -c "
ini_file = '$INI_FILE'
with open(ini_file, 'r') as f:
    lines = f.readlines()
in_section = False
for i, line in enumerate(lines):
    if '[switch-windows]' in line:
        in_section = True
    elif line.startswith('['):
        in_section = False
    if in_section and 'hotkey = alt+§' in line:
        lines[i] = 'hotkey = win+g\n'
        break
with open(ini_file, 'w') as f:
    f.writelines(lines)
"
    echo "Window Switcher: Standard → Voyager (win+g)"
fi

# Restart window-switcher to pick up new config
WS_EXE="C:\\Users\\FilipM\\AppData\\Local\\Programs\\window-switcher\\window-switcher.exe"
powershell.exe -Command "Get-Process -Name 'window-switcher' -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Milliseconds 500; Start-Process '$WS_EXE'" >/dev/null 2>&1 &
