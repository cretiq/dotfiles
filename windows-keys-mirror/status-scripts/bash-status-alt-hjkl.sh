#!/bin/bash

# Check Alt+HJKL navigation remap status
# Returns: "Standard" (ON) or "Voyager" (OFF)

AHK_FILE="${1:-../hotkeys-and-remaps.ahk}"

if [ ! -f "$AHK_FILE" ]; then
    echo "Error: File not found at $AHK_FILE"
    exit 1
fi

if grep -q "^!h::Left$" "$AHK_FILE"; then
    echo "Standard"
else
    echo "Voyager"
fi
