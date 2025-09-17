#!/bin/bash

# Vim Keymap Toggle Script
# Switches between default (HJKL) and custom (JKLÖ) key bindings
# Supports multiple running Vim instances and state persistence

VIM_DIR="$HOME/.dotfiles/vim/.vim"
STATE_FILE="$VIM_DIR/keymap_state"
TRIGGER_FILE="$VIM_DIR/keymap_trigger"
KEYMAPS_DIR="$VIM_DIR/keymaps"
DEFAULT_KEYMAP="$KEYMAPS_DIR/default.vim"
CUSTOM_KEYMAP="$KEYMAPS_DIR/custom.vim"
VSCODE_MANAGER="$HOME/.dotfiles/my_scripts/.script/vscode-vim-keymap-manager.sh"

# Ensure directories exist
mkdir -p "$VIM_DIR" "$KEYMAPS_DIR"

# Function to get current state
get_current_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "default"
    fi
}

# Function to set state
set_state() {
    echo "$1" > "$STATE_FILE"
}

# Function to trigger hot-reload in all running Vim instances
trigger_vim_reload() {
    local mode_name="$1"
    local state_mode="$2"  # "default" or "custom"

    # Find all running Vim instances
    local vim_pids=$(pgrep -f "vim")

    if [[ -n "$vim_pids" ]]; then
        echo "🔄 Triggering hot-reload for $mode_name keymap in running Vim instances..."

        # Create trigger file to signal Vim instances to reload
        touch "$TRIGGER_FILE"

        # Give Vim instances a moment to detect the trigger
        sleep 0.2

        echo "✅ Hot-reload triggered for $(echo "$vim_pids" | wc -l) running Vim session(s)"
    else
        echo "📝 No running Vim instances found. Keymap will apply to new sessions."
    fi

    # Also update VSCode/Cursor if available
    if [[ -x "$VSCODE_MANAGER" ]]; then
        echo "🔄 Updating VSCode/Cursor keybindings..."
        "$VSCODE_MANAGER" "$state_mode"
    fi
}

# Function to toggle keymap
toggle_keymap() {
    local current_state
    current_state=$(get_current_state)

    if [[ "$current_state" == "default" ]]; then
        # Switch to custom
        set_state "custom"
        trigger_vim_reload "custom (JKLÖ)" "custom"
        echo "✅ Switched to CUSTOM keymaps (JKLÖ navigation)"
        echo "📍 State saved: custom"

        # Show notification
        osascript -e 'display notification "Custom JKLÖ navigation activated" with title "Vim Keymaps" subtitle "Terminal + VSCode/Cursor"' 2>/dev/null || true

    else
        # Switch to default
        set_state "default"
        trigger_vim_reload "default (HJKL)" "default"
        echo "✅ Switched to DEFAULT keymaps (HJKL navigation)"
        echo "📍 State saved: default"

        # Show notification
        osascript -e 'display notification "Default HJKL navigation activated" with title "Vim Keymaps" subtitle "Terminal + VSCode/Cursor"' 2>/dev/null || true
    fi
}

# Function to show current status
show_status() {
    local current_state
    current_state=$(get_current_state)

    echo "🔧 Vim Keymap Status"
    echo "===================="
    echo "Current mode: $current_state"

    if [[ "$current_state" == "default" ]]; then
        echo "Navigation: HJKL (standard)"
    else
        echo "Navigation: JKLÖ (custom)"
    fi

    echo ""
    echo "Files:"
    echo "  State: $STATE_FILE"
    echo "  Default: $DEFAULT_KEYMAP"
    echo "  Custom: $CUSTOM_KEYMAP"
}

# Main script logic
case "${1:-toggle}" in
    "toggle")
        toggle_keymap
        ;;
    "status")
        show_status
        ;;
    "default")
        set_state "default"
        trigger_vim_reload "default (HJKL)" "default"
        echo "✅ Forced to DEFAULT keymaps (HJKL)"
        ;;
    "custom")
        set_state "custom"
        trigger_vim_reload "custom (JKLÖ)" "custom"
        echo "✅ Forced to CUSTOM keymaps (JKLÖ)"
        ;;
    *)
        echo "Usage: $0 [toggle|status|default|custom]"
        echo ""
        echo "Commands:"
        echo "  toggle  - Switch between default and custom keymaps (default)"
        echo "  status  - Show current keymap status"
        echo "  default - Force default (HJKL) keymaps"
        echo "  custom  - Force custom (JKLÖ) keymaps"
        exit 1
        ;;
esac