#!/bin/bash

# Toggle ESC/CapsLock remap in hotkeys-and-remaps.ahk
# Usage: ./bash-toggle-esc.sh [file_path]
# Default: ./hotkeys-and-remaps.ahk in current directory

NO_RELOAD=false
for arg in "$@"; do
    [[ "$arg" == "--no-reload" ]] && NO_RELOAD=true
done
FILE_PATH="${1:-./hotkeys-and-remaps.ahk}"

if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File not found at $FILE_PATH"
    exit 1
fi

TEMP_FILE="${FILE_PATH}.tmp"

# Check if ESC remap is currently active (uncommented)
if grep -q "^Esc::CapsLock$" "$FILE_PATH"; then
    # Currently enabled, disable it by commenting out the bindings
    awk '
    /---REMAP ESC---/ { in_section = 1; print; next }
    /^;?---------------$/ && in_section { in_section = 0; print; next }
    in_section && /^Esc::CapsLock$|^CapsLock::Esc$/ { print ";" $0; next }
    { print }
    ' "$FILE_PATH" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$FILE_PATH"
    echo "Disabled ESC/CapsLock remap (commented out)"
else
    # Currently disabled, enable it by uncommenting the bindings
    awk '
    /---REMAP ESC---/ { in_section = 1; print; next }
    /^;?---------------$/ && in_section { in_section = 0; print; next }
    in_section && /^;Esc::CapsLock$|^;CapsLock::Esc$/ { print substr($0, 2); next }
    { print }
    ' "$FILE_PATH" > "$TEMP_FILE"

    mv "$TEMP_FILE" "$FILE_PATH"
    echo "Enabled ESC/CapsLock remap"
fi

# Reload AHK unless --no-reload (caller handles reload)
if [[ "$NO_RELOAD" == false ]]; then
    WIN_PATH=$(wslpath -w "$FILE_PATH")
    AHK_EXE="/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey.exe"
    "$AHK_EXE" "$WIN_PATH" >/dev/null 2>&1 &
fi
