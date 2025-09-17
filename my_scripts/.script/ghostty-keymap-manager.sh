#!/bin/bash

# Ghostty Keymap Manager
# Manages pane navigation keymap switching for Ghostty terminal
# Integrates with the main vim-keymap-toggle.sh system

# =============================================================================
# CONFIGURATION
# =============================================================================

APP_NAME="ghostty"
APP_DISPLAY_NAME="Ghostty"
CONFIG_FILE="$HOME/.dotfiles/ghostty/.config/ghostty/config"
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/ghostty-backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to detect if Ghostty is installed
detect_app() {
    if command -v ghostty &> /dev/null; then
        echo "installed"
        return 0
    fi

    # Check for macOS app bundle
    if [[ -d "/Applications/Ghostty.app" ]]; then
        echo "installed"
        return 0
    fi

    echo "not-installed"
    return 1
}

# Function to check if Ghostty is currently running
is_app_running() {
    if pgrep -f "Ghostty" &> /dev/null; then
        echo "running"
        return 0
    fi
    echo "not-running"
    return 1
}

# Function to backup current configuration
backup_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "⚠️  Config file not found: $CONFIG_FILE"
        return 1
    fi

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/config-${timestamp}.txt"

    cp "$CONFIG_FILE" "$backup_file"
    echo "📁 Backup created: $backup_file"
    return 0
}

# =============================================================================
# KEYMAP DEFINITIONS
# =============================================================================

# Function to get default HJKL pane navigation keybindings
get_default_keybindings() {
    cat << 'EOF'
# Split Navigation (vim-style)
keybind = cmd+h=goto_split:left
keybind = cmd+l=goto_split:right
keybind = cmd+j=goto_split:down
keybind = cmd+k=goto_split:up
EOF
}

# Function to get custom JKLÖ pane navigation keybindings
get_custom_keybindings() {
    cat << 'EOF'
# Split Navigation (custom JKLÖ style)
keybind = cmd+j=goto_split:left
keybind = cmd+k=goto_split:down
keybind = cmd+l=goto_split:up
keybind = cmd+physical:semicolon=goto_split:right
EOF
}

# =============================================================================
# CORE FUNCTIONALITY
# =============================================================================

# Function to update Ghostty pane navigation keybindings
update_keybindings() {
    local mode="$1"  # "default" or "custom"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        return 1
    fi

    # Create backup
    if ! backup_config; then
        echo "❌ Failed to create backup"
        return 1
    fi

    # Create temporary file for processing
    local temp_file=$(mktemp)

    # Remove existing split navigation keybindings
    sed '/# Split Navigation/,/^$/d' "$CONFIG_FILE" > "$temp_file"

    # Get appropriate keybindings
    local new_keybindings=""
    if [[ "$mode" == "custom" ]]; then
        new_keybindings=$(get_custom_keybindings)
    else
        new_keybindings=$(get_default_keybindings)
    fi

    # Find the right place to insert keybindings (after other keybinds)
    # Look for the last keybind line and insert after it
    local last_keybind_line=$(grep -n "^keybind = " "$temp_file" | tail -1 | cut -d: -f1)

    if [[ -n "$last_keybind_line" ]]; then
        # Insert new keybindings after the last existing keybind
        {
            head -n "$last_keybind_line" "$temp_file"
            echo ""
            echo "$new_keybindings"
            tail -n +$((last_keybind_line + 1)) "$temp_file"
        } > "${temp_file}.new"
        mv "${temp_file}.new" "$temp_file"
    else
        # No existing keybinds found, append at end
        {
            cat "$temp_file"
            echo ""
            echo "$new_keybindings"
        } > "${temp_file}.new"
        mv "${temp_file}.new" "$temp_file"
    fi

    # Replace original config file
    mv "$temp_file" "$CONFIG_FILE"

    echo "✅ Ghostty configuration updated successfully"
    return 0
}

# Function to trigger Ghostty reload (if possible)
trigger_app_reload() {
    local app_status=$(is_app_running)

    if [[ "$app_status" == "running" ]]; then
        echo "🔄 Ghostty configuration updated - restart Ghostty to apply changes"

        # Note: Ghostty doesn't have a built-in config reload mechanism
        # Users need to restart the application or create new windows/tabs
        echo "💡 Tip: Create a new tab (Cmd+T) to use the new keybindings"
    else
        echo "📝 Ghostty not running - changes will apply when Ghostty starts"
    fi
}

# =============================================================================
# MAIN INTERFACE
# =============================================================================

# Function to apply keymap mode
apply_keymap_mode() {
    local mode="$1"  # "default" or "custom"

    local app_status=$(detect_app)
    if [[ "$app_status" == "not-installed" ]]; then
        echo "📝 $APP_DISPLAY_NAME not installed. Skipping."
        return 0
    fi

    echo "🔧 Updating $APP_DISPLAY_NAME settings for $mode mode..."

    if update_keybindings "$mode"; then
        trigger_app_reload

        if [[ "$mode" == "custom" ]]; then
            echo "🎯 $APP_DISPLAY_NAME: CUSTOM (JKLÖ) pane navigation activated"
        else
            echo "🎯 $APP_DISPLAY_NAME: DEFAULT (HJKL) pane navigation activated"
        fi
        return 0
    else
        echo "❌ Failed to update $APP_DISPLAY_NAME keybindings"
        return 1
    fi
}

# Function to restore from most recent backup
restore_from_backup() {
    local latest_backup=$(ls -t "$BACKUP_DIR"/config-*.txt 2>/dev/null | head -1)
    if [[ -n "$latest_backup" ]]; then
        cp "$latest_backup" "$CONFIG_FILE"
        echo "📁 Restored from backup: $latest_backup"
    else
        echo "❌ No backup found to restore from"
    fi
}

# Function to show current status
show_status() {
    echo "🔧 $APP_DISPLAY_NAME Integration Status"
    echo "========================================"

    local app_status=$(detect_app)
    echo "Installation: $app_status"

    if [[ "$app_status" == "installed" ]]; then
        echo "Config file: $CONFIG_FILE"
        echo "Backup directory: $BACKUP_DIR"

        local running_status=$(is_app_running)
        echo "Currently running: $running_status"

        if [[ -f "$CONFIG_FILE" ]]; then
            echo "Config file exists: ✅"

            # Detect current mode by checking keybindings
            if grep -q "cmd+j=goto_split:left" "$CONFIG_FILE" 2>/dev/null; then
                echo "Current mode: CUSTOM (JKLÖ)"
            else
                echo "Current mode: DEFAULT (HJKL)"
            fi
        else
            echo "Config file exists: ❌"
        fi

        # Show backup count
        local backup_count=$(ls "$BACKUP_DIR"/config-*.txt 2>/dev/null | wc -l)
        echo "Backups available: $backup_count"
    fi
}

# =============================================================================
# COMMAND LINE INTERFACE
# =============================================================================

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
    "backup")
        backup_config
        ;;
    "restore")
        restore_from_backup
        ;;
    *)
        echo "Usage: $0 [default|custom|status|backup|restore]"
        echo ""
        echo "Commands:"
        echo "  default  - Apply default (HJKL) pane navigation"
        echo "  custom   - Apply custom (JKLÖ) pane navigation"
        echo "  status   - Show current integration status"
        echo "  backup   - Create manual backup of current config"
        echo "  restore  - Restore from most recent backup"
        exit 1
        ;;
esac