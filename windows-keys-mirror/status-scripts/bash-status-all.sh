#!/bin/bash

# Display all remap statuses together

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AHK_FILE="${1:-$SCRIPT_DIR/../hotkeys-and-remaps.ahk}"

if [ ! -f "$AHK_FILE" ]; then
    echo "Error: File not found at $AHK_FILE"
    exit 1
fi

# Get individual statuses
esc_status=$("$SCRIPT_DIR/bash-status-esc.sh" "$AHK_FILE")
hjkl_status=$("$SCRIPT_DIR/bash-status-alt-hjkl.sh" "$AHK_FILE")
vim_status=$("$SCRIPT_DIR/bash-status-vim.sh" 2>/dev/null)
vim_layout=$("$SCRIPT_DIR/bash-status-vim.sh" layout 2>/dev/null)

# Display
echo "=== Remap Status ==="
echo "ESC/CapsLock:      $esc_status"
echo "Alt+HJKL:          $hjkl_status"
echo ""
echo "=== Vim Status ==="
echo "Vim Keymap:        $vim_status"
echo "Vim Layout:        $vim_layout"
