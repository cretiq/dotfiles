#!/bin/bash

# Check Vim keymap layout status
# Returns: "HJKL" or "JKLÖ" based on current layout

STATE_FILE="$HOME/.dotfiles/vim/.vim/keymap_state"

# Get the current state
if [ -f "$STATE_FILE" ]; then
    state=$(cat "$STATE_FILE")
else
    # Fallback: check if vim script exists and call it
    if [ -x "/home/filip/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh" ]; then
        state=$(/home/filip/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh status 2>/dev/null | grep "Current mode:" | awk '{print $NF}')
    else
        echo "Unable to determine"
        exit 0
    fi
fi

# Return the corresponding layout
if [ "$state" = "custom" ]; then
    echo "Voyager"
elif [ "$state" = "default" ]; then
    echo "Standard"
else
    echo "Unknown"
fi
