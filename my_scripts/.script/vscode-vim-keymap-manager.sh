#!/bin/bash

# VSCode/Cursor Vim Keymap Manager
# Manages dynamic keybinding switching for VSCodeVim extension
# Integrates with the main vim-keymap-toggle.sh system

CURSOR_SETTINGS="/Users/filipmellqvist/Library/Application Support/Cursor/User/settings.json"
VSCODE_SETTINGS="/Users/filipmellqvist/Library/Application Support/Code/User/settings.json"
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/vscode-backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to detect which editor is being used
detect_editor() {
    local active_settings=""

    if [[ -f "$CURSOR_SETTINGS" ]]; then
        active_settings="$CURSOR_SETTINGS"
        echo "cursor"
    elif [[ -f "$VSCODE_SETTINGS" ]]; then
        active_settings="$VSCODE_SETTINGS"
        echo "vscode"
    else
        echo "none"
    fi
}

# Function to backup current settings
backup_settings() {
    local editor="$1"
    local settings_file=""

    case "$editor" in
        "cursor")
            settings_file="$CURSOR_SETTINGS"
            ;;
        "vscode")
            settings_file="$VSCODE_SETTINGS"
            ;;
        *)
            echo "❌ Unknown editor: $editor"
            return 1
            ;;
    esac

    if [[ -f "$settings_file" ]]; then
        local backup_file="$BACKUP_DIR/settings-$(date +%Y%m%d-%H%M%S).json"
        cp "$settings_file" "$backup_file"
        echo "📁 Backup created: $backup_file"
    fi
}

# Function to get default HJKL keybindings
get_default_keybindings() {
    cat << 'EOF'
    "vim.normalModeKeyBindingsNonRecursive": [
        {
            "before": ["u"],
            "commands": ["undo"]
        },
        {
            "before": ["U"],
            "commands": ["redo"]
        }
    ],
EOF
}

# Function to get custom JKLÖ keybindings
get_custom_keybindings() {
    cat << 'EOF'
    "vim.normalModeKeyBindingsNonRecursive": [
        {
            "before": ["u"],
            "commands": ["undo"]
        },
        {
            "before": ["U"],
            "commands": ["redo"]
        },
        {
            "before": ["j"],
            "after": ["h"]
        },
        {
            "before": ["k"],
            "after": ["j"]
        },
        {
            "before": ["l"],
            "after": ["k"]
        },
        {
            "before": ["ö"],
            "after": ["l"]
        }
    ],
    "vim.visualModeKeyBindingsNonRecursive": [
        {
            "before": ["j"],
            "after": ["h"]
        },
        {
            "before": ["k"],
            "after": ["j"]
        },
        {
            "before": ["l"],
            "after": ["k"]
        },
        {
            "before": ["ö"],
            "after": ["l"]
        }
    ],
    "vim.operatorPendingModeKeyBindingsNonRecursive": [
        {
            "before": ["j"],
            "after": ["h"]
        },
        {
            "before": ["k"],
            "after": ["j"]
        },
        {
            "before": ["l"],
            "after": ["k"]
        },
        {
            "before": ["ö"],
            "after": ["l"]
        }
    ],
EOF
}

# Function to update VSCode/Cursor settings
update_vscode_keybindings() {
    local mode="$1"  # "default" or "custom"
    local editor="$2"
    local settings_file=""

    case "$editor" in
        "cursor")
            settings_file="$CURSOR_SETTINGS"
            ;;
        "vscode")
            settings_file="$VSCODE_SETTINGS"
            ;;
        *)
            echo "❌ Unknown editor: $editor"
            return 1
            ;;
    esac

    if [[ ! -f "$settings_file" ]]; then
        echo "❌ Settings file not found: $settings_file"
        return 1
    fi

    # Use the Python updater script
    local updater="$HOME/.dotfiles/my_scripts/.script/update-vscode-keybindings.py"
    if [[ -x "$updater" ]]; then
        "$updater" "$settings_file" "$mode" "$BACKUP_DIR"
        return $?
    else
        echo "❌ VSCode keybinding updater not found: $updater"
        return 1
    fi
}

# Function to apply keymap mode
apply_keymap_mode() {
    local mode="$1"  # "default" or "custom"
    local editor=$(detect_editor)

    if [[ "$editor" == "none" ]]; then
        echo "📝 No VSCode/Cursor installation found. Skipping VSCode integration."
        return 0
    fi

    echo "🔧 Updating $editor settings for $mode mode..."

    if update_vscode_keybindings "$mode" "$editor"; then
        if [[ "$mode" == "custom" ]]; then
            echo "🎯 VSCode/Cursor: CUSTOM (JKLÖ) keybindings activated"
        else
            echo "🎯 VSCode/Cursor: DEFAULT (HJKL) keybindings activated"
        fi
        return 0
    else
        echo "❌ Failed to update VSCode/Cursor keybindings"
        return 1
    fi
}

# Function to show current status
show_status() {
    local editor=$(detect_editor)
    echo "🔧 VSCode/Cursor Vim Integration Status"
    echo "======================================"
    echo "Editor detected: $editor"

    if [[ "$editor" != "none" ]]; then
        local settings_file=""
        case "$editor" in
            "cursor") settings_file="$CURSOR_SETTINGS" ;;
            "vscode") settings_file="$VSCODE_SETTINGS" ;;
        esac

        echo "Settings file: $settings_file"
        echo "Backup directory: $BACKUP_DIR"

        # Check if custom keybindings are present
        if grep -q '"ö"' "$settings_file" 2>/dev/null; then
            echo "Current mode: CUSTOM (JKLÖ)"
        else
            echo "Current mode: DEFAULT (HJKL)"
        fi
    fi
}

# Main script logic
case "${1:-status}" in
    "default")
        apply_keymap_mode "default"
        ;;
    "custom")
        apply_keymap_mode "custom"
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 [default|custom|status]"
        echo ""
        echo "Commands:"
        echo "  default - Apply default (HJKL) keybindings to VSCode/Cursor"
        echo "  custom  - Apply custom (JKLÖ) keybindings to VSCode/Cursor"
        echo "  status  - Show current VSCode/Cursor integration status"
        exit 1
        ;;
esac