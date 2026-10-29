#!/bin/bash

# Get all status values in one call
# Usage: ./get-all-status.sh [ahk_file_path]
# Output: ESC|HJKL|VIM|NVIM|OBSIDIAN|RANGER|WINDOW_SWITCHER|WINDOWS_TERMINAL

AHK_FILE="${1:-../hotkeys-and-remaps.ahk}"

# Check ESC status
if [ -f "$AHK_FILE" ] && grep -q "^Esc::CapsLock$" "$AHK_FILE"; then
    ESC_STATUS="Standard"
else
    ESC_STATUS="Voyager"
fi

# Check HJKL status
if [ -f "$AHK_FILE" ] && grep -q "^!h::Left$" "$AHK_FILE"; then
    HJKL_STATUS="Standard"
else
    HJKL_STATUS="Voyager"
fi

# Check Vim status
STATE_FILE="$HOME/.dotfiles/vim/.vim/keymap_state"
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
    if [ "$state" = "custom" ]; then
        VIM_STATUS="Voyager"
    elif [ "$state" = "default" ]; then
        VIM_STATUS="Standard"
    else
        VIM_STATUS="Unknown"
    fi
else
    VIM_STATUS="Unknown"
fi

# Check Neovim status (reads same keymap_state file as Vim)
if [ -f "$STATE_FILE" ]; then
    if [ "$(cat "$STATE_FILE")" = "custom" ]; then
        NVIM_STATUS="Voyager"
    else
        NVIM_STATUS="Standard"
    fi
else
    NVIM_STATUS="Standard"
fi

# Check Obsidian status
OBSIDIAN_VIMRC="/mnt/c/Users/FilipM/Documents/Obsidian/RCO/.obsidian.vimrc"
if [ -f "$OBSIDIAN_VIMRC" ] && grep -q "nnoremap j h" "$OBSIDIAN_VIMRC" 2>/dev/null; then
    OBSIDIAN_STATUS="Voyager"
else
    OBSIDIAN_STATUS="Standard"
fi

# Check Ranger status
RANGER_CONFIG="$HOME/.config/ranger/rc.conf"
if [ -f "$RANGER_CONFIG" ] && grep -q "^copymap <LEFT>     j" "$RANGER_CONFIG" 2>/dev/null; then
    RANGER_STATUS="Voyager"
else
    RANGER_STATUS="Standard"
fi

# Check Window Switcher status
WS_INI="/mnt/c/Users/FilipM/AppData/Local/Programs/window-switcher/window-switcher.ini"
if [ -f "$WS_INI" ] && awk '/^\[switch-windows\]/{f=1} f && /^hotkey/{print; exit}' "$WS_INI" | grep -q "win+g"; then
    WS_STATUS="Voyager"
else
    WS_STATUS="Standard"
fi

WT_SETTINGS="/mnt/c/Users/FilipM/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
if [ -f "$WT_SETTINGS" ] && awk '/"id": "Terminal.MoveFocusLeft"/{getline; print}' "$WT_SETTINGS" | grep -q '"ctrl+j"'; then
    WT_STATUS="Voyager"
else
    WT_STATUS="Standard"
fi

# Output all statuses separated by pipe
echo "$ESC_STATUS|$HJKL_STATUS|$VIM_STATUS|$NVIM_STATUS|$OBSIDIAN_STATUS|$RANGER_STATUS|$WS_STATUS|$WT_STATUS"
