#!/bin/bash

# Superfile Keymap Manager
# Manages keymap switching for Superfile terminal file manager
# Integrates with the main vim-keymap-toggle.sh system

# =============================================================================
# CONFIGURATION
# =============================================================================

APP_NAME="superfile"
APP_DISPLAY_NAME="Superfile"
CONFIG_FILE="$HOME/Library/Application Support/superfile/hotkeys.toml"
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/superfile-backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to detect if Superfile is installed
detect_app() {
    if command -v spf &> /dev/null || command -v superfile &> /dev/null; then
        echo "installed"
        return 0
    fi

    echo "not-installed"
    return 1
}

# Function to check if Superfile is currently running
is_app_running() {
    if pgrep -f "superfile\|spf" &> /dev/null; then
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
    local backup_file="$BACKUP_DIR/hotkeys-${timestamp}.toml"

    cp "$CONFIG_FILE" "$backup_file"
    echo "📁 Backup created: $backup_file"
    return 0
}

# =============================================================================
# KEYMAP DEFINITIONS
# =============================================================================

# Function to get default HJKL navigation keybindings
get_default_keybindings() {
    cat << 'EOF'
# =================================================================================================
# Global hotkeys (cannot conflict with other hotkeys)
confirm = ['enter', 'right', 'l']
quit = ['q', 'esc']

# movement
list_up = ['up', 'k']
list_down = ['down', 'j']
page_up = ['pgup','']
page_down = ['pgdown','']
# file panel control
create_new_file_panel = ['n', '']
close_file_panel = ['w', '']
next_file_panel = ['tab', 'L']
previous_file_panel = ['shift+left', 'H']
toggle_file_preview_panel = ['f', '']
open_sort_options_menu = ['o', '']
toggle_reverse_sort = ['R', '']
# change focus
focus_on_process_bar = ['p', '']
focus_on_sidebar = ['s', '']
focus_on_metadata = ['m', '']
# create file/directory and rename
file_panel_item_create = ['ctrl+n', '']
file_panel_item_rename = ['ctrl+r', '']
# file operations
copy_items = ['ctrl+c', '']
cut_items = ['ctrl+x', '']
paste_items = ['ctrl+v', 'ctrl+w', '']
delete_items = ['ctrl+d', 'delete', '']
# compress and extract
extract_file = ['ctrl+e', '']
compress_file = ['ctrl+a', '']
# editor
open_file_with_editor = ['e', '']
open_current_directory_with_editor = ['E', '']
# other
pinned_directory = ['P', '']
toggle_dot_file = ['.', '']
change_panel_mode = ['v', '']
open_help_menu = ['?', '']
open_command_line = [':', '']
open_spf_prompt = ['>', '']
copy_path = ['ctrl+p', '']
copy_present_working_directory = ['c', '']
toggle_footer = ['F', '']
# =================================================================================================
# Typing hotkeys (can conflict with all hotkeys)
confirm_typing = ['enter', '']
cancel_typing = ['ctrl+c', 'esc']
# =================================================================================================
# Normal mode hotkeys (can conflict with other modes, cannot conflict with global hotkeys)
parent_directory = ['h', 'left', 'backspace']
search_bar = ['/', '']
# =================================================================================================
# Select mode hotkeys (can conflict with other modes, cannot conflict with global hotkeys)
file_panel_select_mode_items_select_down = ['shift+down', 'J']
file_panel_select_mode_items_select_up = ['shift+up', 'K']
file_panel_select_all_items = ['A', '']
EOF
}

# Function to get custom JKLÖ navigation keybindings
get_custom_keybindings() {
    cat << 'EOF'
# =================================================================================================
# Global hotkeys (cannot conflict with other hotkeys)
confirm = ['enter', 'right', 'ö']
quit = ['q', 'esc']

# movement (JKLÖ custom layout)
list_up = ['up', 'l']
list_down = ['down', 'k']
page_up = ['pgup','']
page_down = ['pgdown','']
# file panel control
create_new_file_panel = ['n', '']
close_file_panel = ['w', '']
next_file_panel = ['tab', 'L']
previous_file_panel = ['shift+left', 'H']
toggle_file_preview_panel = ['f', '']
open_sort_options_menu = ['o', '']
toggle_reverse_sort = ['R', '']
# change focus
focus_on_process_bar = ['p', '']
focus_on_sidebar = ['s', '']
focus_on_metadata = ['m', '']
# create file/directory and rename
file_panel_item_create = ['ctrl+n', '']
file_panel_item_rename = ['ctrl+r', '']
# file operations
copy_items = ['ctrl+c', '']
cut_items = ['ctrl+x', '']
paste_items = ['ctrl+v', 'ctrl+w', '']
delete_items = ['ctrl+d', 'delete', '']
# compress and extract
extract_file = ['ctrl+e', '']
compress_file = ['ctrl+a', '']
# editor
open_file_with_editor = ['e', '']
open_current_directory_with_editor = ['E', '']
# other
pinned_directory = ['P', '']
toggle_dot_file = ['.', '']
change_panel_mode = ['v', '']
open_help_menu = ['?', '']
open_command_line = [':', '']
open_spf_prompt = ['>', '']
copy_path = ['ctrl+p', '']
copy_present_working_directory = ['c', '']
toggle_footer = ['F', '']
# =================================================================================================
# Typing hotkeys (can conflict with all hotkeys)
confirm_typing = ['enter', '']
cancel_typing = ['ctrl+c', 'esc']
# =================================================================================================
# Normal mode hotkeys (can conflict with other modes, cannot conflict with global hotkeys)
parent_directory = ['j', 'left', 'backspace']
search_bar = ['/', '']
# =================================================================================================
# Select mode hotkeys (can conflict with other modes, cannot conflict with global hotkeys)
file_panel_select_mode_items_select_down = ['shift+down', 'K']
file_panel_select_mode_items_select_up = ['shift+up', 'L']
file_panel_select_all_items = ['A', '']
EOF
}

# =============================================================================
# CORE FUNCTIONALITY
# =============================================================================

# Function to update Superfile navigation keybindings
update_keybindings() {
    local mode="$1"  # "default" or "custom"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "❌ Configuration file not found: $CONFIG_FILE"
        echo "💡 Tip: Run Superfile once to generate the config file"
        return 1
    fi

    # Create backup
    if ! backup_config; then
        echo "❌ Failed to create backup"
        return 1
    fi

    # Get appropriate keybindings and write to config file
    if [[ "$mode" == "custom" ]]; then
        get_custom_keybindings > "$CONFIG_FILE"
    else
        get_default_keybindings > "$CONFIG_FILE"
    fi

    echo "✅ Superfile configuration updated successfully"
    return 0
}

# Function to trigger Superfile reload (if possible)
trigger_app_reload() {
    local app_status=$(is_app_running)

    if [[ "$app_status" == "running" ]]; then
        echo "🔄 Superfile configuration updated - restart Superfile to apply changes"
        echo "💡 Tip: Press 'q' to quit and restart Superfile"
    else
        echo "📝 Superfile not running - changes will apply when Superfile starts"
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
            echo "🎯 $APP_DISPLAY_NAME: CUSTOM (JKLÖ) navigation activated"
        else
            echo "🎯 $APP_DISPLAY_NAME: DEFAULT (HJKL) navigation activated"
        fi
        return 0
    else
        echo "❌ Failed to update $APP_DISPLAY_NAME keybindings"
        return 1
    fi
}

# Function to restore from most recent backup
restore_from_backup() {
    local latest_backup=$(ls -t "$BACKUP_DIR"/hotkeys-*.toml 2>/dev/null | head -1)
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
            if grep -q "list_up = \['up', 'l'\]" "$CONFIG_FILE" 2>/dev/null; then
                echo "Current mode: CUSTOM (JKLÖ)"
            else
                echo "Current mode: DEFAULT (HJKL)"
            fi
        else
            echo "Config file exists: ❌"
            echo "💡 Run Superfile once to generate initial config"
        fi

        # Show backup count
        local backup_count=$(ls "$BACKUP_DIR"/hotkeys-*.toml 2>/dev/null | wc -l)
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
        echo "  default  - Apply default (HJKL) navigation"
        echo "  custom   - Apply custom (JKLÖ) navigation"
        echo "  status   - Show current integration status"
        echo "  backup   - Create manual backup of current config"
        echo "  restore  - Restore from most recent backup"
        exit 1
        ;;
esac