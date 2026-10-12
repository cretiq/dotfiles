#!/bin/bash

# Check Neovim keymap status
# Returns: "Standard" (HJKL) or "Voyager" (JKLÖ)

KEYMAPS_FILE="$HOME/.config/nvim/lua/keymaps.lua"

if [[ -f "$KEYMAPS_FILE" ]] && grep -q 'M.mode = "custom"' "$KEYMAPS_FILE" 2>/dev/null; then
    echo "Voyager"
else
    echo "Standard"
fi
