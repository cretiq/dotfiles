#!/bin/bash

# VSCode Vim Keymap Manager
# Manages dynamic keybinding switching for VSCode Vim extension
# Integrates with the main vim-keymap-toggle.sh system

# ============================================================================
# PERSISTENT KEYBINDINGS CONFIGURATION
# ============================================================================
# Add any keybindings here that should be preserved across all keymap toggles.
# These will be automatically merged with the movement keybindings.
# Format: standard VSCode keybinding JSON objects
# Example:
#   {
#       "key": "ctrl+p",
#       "command": "-extension.vim_ctrl+p",
#       "when": "condition"
#   },
# ============================================================================
PERSISTENT_KEYBINDINGS='[
    {
        "key": "ctrl+p",
        "command": "-extension.vim_ctrl+p",
        "when": "editorTextFocus && vim.active && vim.use<C-p> && !inDebugRepl || vim.active && vim.use<C-p> && !inDebugRepl && vim.mode == '\''CommandlineInProgress'\'' || vim.active && vim.use<C-p> && !inDebugRepl && vim.mode == '\''SearchInProgressMode'\''"
    }
]'
# ============================================================================

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

    # Get the new movement keybindings as full JSON array
    local movement_bindings
    if [[ "$mode" == "custom" ]]; then
        movement_bindings=$(get_custom_keybindings)
    else
        movement_bindings=$(get_default_keybindings)
    fi

    # Use Python to merge keybindings (more reliable than jq)
    python3 << PYTHON_EOF
import json
import sys

# Movement keys to filter out
MOVEMENT_KEYS = {'h', 'j', 'k', 'l', 'ö'}

try:
    # Read existing keybindings
    existing_custom_bindings = []
    if '$KEYBINDINGS_FILE' and __import__('os').path.isfile('$KEYBINDINGS_FILE'):
        with open('$KEYBINDINGS_FILE', 'r', encoding='utf-8') as f:
            existing = json.load(f)
            # Keep only non-movement keybindings
            existing_custom_bindings = [b for b in existing if b.get('key') not in MOVEMENT_KEYS]

    # Parse new movement bindings
    movement_bindings = json.loads('''$movement_bindings''')

    # Combine: movement bindings first, then custom bindings
    combined = movement_bindings + existing_custom_bindings

    # Write the merged result
    with open('$KEYBINDINGS_FILE', 'w', encoding='utf-8') as f:
        json.dump(combined, f, indent=4, ensure_ascii=False)

    sys.exit(0)

except Exception as e:
    print(f"❌ Error merging keybindings: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_EOF

    if [[ $? -eq 0 ]]; then
        echo "✅ Updated: $KEYBINDINGS_FILE (preserved custom keybindings)"
        return 0
    else
        echo "❌ Failed to merge keybindings. Rolling back from backup."
        latest_backup=$(ls -t "$BACKUP_DIR"/keybindings-*.bak 2>/dev/null | head -1)
        if [[ -n "$latest_backup" ]]; then
            cp "$latest_backup" "$KEYBINDINGS_FILE"
        fi
        return 1
    fi
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
