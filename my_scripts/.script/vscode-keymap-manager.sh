#!/bin/bash

# VSCode Vim Keymap Manager
# Manages dynamic keybinding switching for VSCode Vim extension
# Integrates with the main vim-keymap-toggle.sh system

# VSCode config locations (Windows paths via WSL2)
VSCODE_CONFIG_DIR="/mnt/c/Users/FilipM/AppData/Roaming/Code/User"
KEYBINDINGS_FILE="$VSCODE_CONFIG_DIR/keybindings.json"
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/vscode-backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Function to backup current keybindings
backup_keybindings() {
    if [[ -f "$KEYBINDINGS_FILE" ]]; then
        local backup_file="$BACKUP_DIR/keybindings-$(date +%Y%m%d-%H%M%S).bak"
        cp "$KEYBINDINGS_FILE" "$backup_file"
        echo "📁 Backup created: $backup_file"
        return 0
    fi
    return 1
}

# Function to get default HJKL keybindings
get_default_keybindings() {
    cat << 'EOF'
[
    {
        "key": "h",
        "command": "cursorLeft",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "j",
        "command": "cursorDown",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "k",
        "command": "cursorUp",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "l",
        "command": "cursorRight",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "h",
        "command": "cursorLeftSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "j",
        "command": "cursorDownSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "k",
        "command": "cursorUpSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "l",
        "command": "cursorRightSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "h",
        "command": "cursorLeftSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "j",
        "command": "cursorDownSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "k",
        "command": "cursorUpSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "l",
        "command": "cursorRightSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "h",
        "command": "cursorLeftSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "j",
        "command": "cursorDownSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "k",
        "command": "cursorUpSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "l",
        "command": "cursorRightSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "h",
        "command": "cursorLeft",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    },
    {
        "key": "j",
        "command": "cursorDown",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    },
    {
        "key": "k",
        "command": "cursorUp",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    },
    {
        "key": "l",
        "command": "cursorRight",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    }
]
EOF
}

# Function to get custom JKLÖ keybindings
get_custom_keybindings() {
    cat << 'EOF'
[
    {
        "key": "j",
        "command": "cursorLeft",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "k",
        "command": "cursorDown",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "l",
        "command": "cursorUp",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "ö",
        "command": "cursorRight",
        "when": "editorTextFocus && vim.active && vim.mode == 'Normal'"
    },
    {
        "key": "j",
        "command": "cursorLeftSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "k",
        "command": "cursorDownSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "l",
        "command": "cursorUpSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "ö",
        "command": "cursorRightSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'Visual'"
    },
    {
        "key": "j",
        "command": "cursorLeftSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "k",
        "command": "cursorDownSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "l",
        "command": "cursorUpSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "ö",
        "command": "cursorRightSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualLine'"
    },
    {
        "key": "j",
        "command": "cursorLeftSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "k",
        "command": "cursorDownSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "l",
        "command": "cursorUpSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "ö",
        "command": "cursorRightSelect",
        "when": "editorTextFocus && vim.active && vim.mode == 'VisualBlock'"
    },
    {
        "key": "j",
        "command": "cursorLeft",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    },
    {
        "key": "k",
        "command": "cursorDown",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    },
    {
        "key": "l",
        "command": "cursorUp",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    },
    {
        "key": "ö",
        "command": "cursorRight",
        "when": "editorTextFocus && vim.active && vim.mode == 'Replace'"
    }
]
EOF
}

# Function to update VSCode keybindings
update_keybindings() {
    local mode="$1"  # "default" or "custom"

    if [[ ! -d "$VSCODE_CONFIG_DIR" ]]; then
        echo "❌ VSCode config directory not found: $VSCODE_CONFIG_DIR"
        return 1
    fi

    # Create backup of existing keybindings
    if [[ -f "$KEYBINDINGS_FILE" ]]; then
        backup_keybindings
    fi

    # Get the new keybindings and extract just the JSON array content (without outer brackets)
    local new_bindings
    if [[ "$mode" == "custom" ]]; then
        new_bindings=$(get_custom_keybindings | sed '1d;$d')
    else
        new_bindings=$(get_default_keybindings | sed '1d;$d')
    fi

    # Create new keybindings file with proper JSON array
    echo "[" > "$KEYBINDINGS_FILE"
    echo "$new_bindings" >> "$KEYBINDINGS_FILE"
    echo "]" >> "$KEYBINDINGS_FILE"

    echo "✅ Updated: $KEYBINDINGS_FILE"
    return 0
}

# Function to apply keymap mode
apply_keymap_mode() {
    local mode="$1"  # "default" or "custom"

    if [[ ! -d "$VSCODE_CONFIG_DIR" ]]; then
        echo "📝 VSCode config directory not found. Skipping VSCode integration."
        return 0
    fi

    echo "🔧 Updating VSCode keybindings for $mode mode..."

    if update_keybindings "$mode"; then
        if [[ "$mode" == "custom" ]]; then
            echo "🎯 VSCode: CUSTOM (JKLÖ) keybindings activated"
        else
            echo "🎯 VSCode: DEFAULT (HJKL) keybindings activated"
        fi
        return 0
    else
        echo "❌ Failed to update VSCode keybindings"
        return 1
    fi
}

# Function to show current status
show_status() {
    echo "🔧 VSCode Integration Status"
    echo "===================================="

    if [[ ! -d "$VSCODE_CONFIG_DIR" ]]; then
        echo "Status: VSCode config directory not found"
        return 0
    fi

    echo "Config directory: $VSCODE_CONFIG_DIR"
    echo "Backup directory: $BACKUP_DIR"

    if [[ -f "$KEYBINDINGS_FILE" ]]; then
        echo "Keybindings file exists: ✅"

        # Detect current mode by checking keybindings
        if grep -q '"key": "j"' "$KEYBINDINGS_FILE" 2>/dev/null; then
            if grep -q '"command": "cursorLeft"' "$KEYBINDINGS_FILE" 2>/dev/null; then
                # Check if it's custom by looking for j = cursorLeft pattern
                if grep -A1 '"key": "j"' "$KEYBINDINGS_FILE" | grep -q '"command": "cursorLeft"'; then
                    echo "Current mode: CUSTOM (JKLÖ)"
                else
                    echo "Current mode: DEFAULT (HJKL)"
                fi
            fi
        else
            echo "Current mode: DEFAULT (HJKL)"
        fi
    else
        echo "Keybindings file exists: ❌"
    fi

    # Show backup count
    local backup_count=$(ls "$BACKUP_DIR"/keybindings-*.bak 2>/dev/null | wc -l)
    echo "Backups available: $backup_count"

    echo ""
    echo "📌 IMPORTANT: Ctrl Key Configuration"
    echo "===================================="
    echo "To prevent Vim from using Ctrl keys (preserving Ctrl+P, etc):"
    echo "1. In VSCode, go to Settings"
    echo "2. Search for 'vim.commandLineModeKeyBindings' and 'vim.normalModeKeyBindings'"
    echo "3. Disable default VSCodeVim Ctrl keybindings"
    echo "4. Alternatively, manually edit settings.json with custom bindings that exclude Ctrl keys"
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
        echo "  default - Apply default (HJKL) keybindings to VSCode"
        echo "  custom  - Apply custom (JKLÖ) keybindings to VSCode"
        echo "  status  - Show current VSCode integration status"
        exit 1
        ;;
esac
