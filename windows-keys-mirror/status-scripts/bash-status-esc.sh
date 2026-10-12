#!/bin/bash

# Check ESC/CapsLock remap status
# Returns: "Standard" (ON) or "Voyager" (OFF)

AHK_FILE="${1:-../hotkeys-and-remaps.ahk}"

if [ ! -f "$AHK_FILE" ]; then
    echo "Error: File not found at $AHK_FILE"
    exit 1
fi

if grep -q "^Esc::CapsLock$" "$AHK_FILE"; then
    echo "Standard"
else
    echo "Voyager"
fi
