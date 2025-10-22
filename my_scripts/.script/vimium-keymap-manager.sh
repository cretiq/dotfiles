#!/bin/bash

# Vimium Keymap Manager
# Manages keymap switching for Vimium browser extension in Microsoft Edge
# Integrates with the main vim-keymap-toggle.sh system

# =============================================================================
# CONFIGURATION
# =============================================================================

APP_NAME="vimium"
APP_DISPLAY_NAME="Vimium C (Edge)"
EDGE_BASE_PATH="$HOME/Library/Application Support/Microsoft Edge"
VIMIUM_EXTENSION_ID="aibcglbfblnogfjhbcmmpobjhnomhcdo"  # Vimium C extension ID for Edge
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/vimium-backups"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Function to detect if Edge and Vimium are installed
detect_app() {
    # Check if Edge base directory exists
    if [[ ! -d "$EDGE_BASE_PATH" ]]; then
        echo "edge-not-installed"
        return 1
    fi

    # Look for Vimium extension in any profile
    local found_profiles=()
    for profile_dir in "$EDGE_BASE_PATH"/Profile*; do
        if [[ -d "$profile_dir" ]]; then
            local profile_name=$(basename "$profile_dir")
            local vimium_path="$profile_dir/Extensions/$VIMIUM_EXTENSION_ID"
            if [[ -d "$vimium_path" ]]; then
                found_profiles+=("$profile_name")
            fi
        fi
    done

    if [[ ${#found_profiles[@]} -gt 0 ]]; then
        echo "installed"
        return 0
    fi

    echo "vimium-not-installed"
    return 1
}

# Function to check if Edge is currently running
is_edge_running() {
    if pgrep -f "Microsoft Edge" &> /dev/null; then
        echo "running"
        return 0
    fi
    echo "not-running"
    return 1
}

# Function to find Vimium extension storage paths
find_vimium_storage() {
    local found_paths=()

    for profile_dir in "$EDGE_BASE_PATH"/Profile*; do
        if [[ -d "$profile_dir" ]]; then
            local profile_name=$(basename "$profile_dir")
            local vimium_path="$profile_dir/Extensions/$VIMIUM_EXTENSION_ID"

            if [[ -d "$vimium_path" ]]; then
                # Find the version directory (usually something like "2.1.2_0")
                local version_dir=$(ls -1 "$vimium_path" | head -1)
                if [[ -n "$version_dir" && -d "$vimium_path/$version_dir" ]]; then
                    found_paths+=("$profile_name:$vimium_path/$version_dir")
                fi
            fi
        fi
    done

    printf '%s\n' "${found_paths[@]}"
}

# Function to get Vimium options storage path
get_vimium_options_file() {
    # Vimium stores its options in Edge's storage API
    # We'll write instructions for manual configuration since browser extensions
    # use internal storage that's not easily accessible via file system
    echo ""
}

# =============================================================================
# KEYMAP DEFINITIONS
# =============================================================================

# Function to get default HJKL navigation mappings for Vimium
get_default_keybindings() {
    cat << 'EOF'
# Default Vim navigation (HJKL)
# These are the standard Vimium bindings - no custom mappings needed
# h/j/k/l work as expected: left/down/up/right

# Remove any custom mappings to restore defaults
unmapAll
EOF
}

# Function to get custom JKLÖ navigation mappings for Vimium
get_custom_keybindings() {
    cat << 'EOF'
# Custom JKLÖ navigation mappings
# Remaps j/k/l/ö to match your custom vim layout

# Clear all default mappings first
unmapAll

# Custom navigation mappings (JKLÖ style)
map j scrollLeft
map k scrollDown
map l scrollUp
map ö scrollRight

# Remap shifted versions for larger movements
map J previousTab
map K scrollPageDown
map L scrollPageUp
map Ö nextTab

# Essential Vimium commands with new keys
map f LinkHints.activateMode
map F LinkHints.activateModeToOpenInNewTab
map r reload
map R reloadGrayscale
map t createTab
map x removeTab
map X restoreTab
map d scrollPageDown
map u scrollPageUp
map gg scrollToTop
map G scrollToBottom
map H goBack
map yy copyCurrentUrl
map p openCopiedUrlInCurrentTab
map P openCopiedUrlInNewTab
map o Vomnibar.activate
map O Vomnibar.activateInNewTab
map b Vomnibar.activateBookmarks
map B Vomnibar.activateBookmarksInNewTab
map T Vomnibar.activateTabSelection
map / enterFindMode
map n performFind
map N performBackwardsFind
map i enterInsertMode
map v enterVisualMode
map V enterVisualLineMode
map <c-e> scrollDown
map <c-y> scrollUp
map <c-d> scrollPageDown
map <c-u> scrollPageUp
map <c-f> scrollFullPageDown
map <c-b> scrollFullPageUp
map yt duplicateTab
map <a-p> togglePinTab
map <a-m> toggleMuteTab
map ? showHelp
map ge nextFrame
map gf selectFirstFrame
map gF selectMainFrame

# Keep standard commands that don't conflict
map 0 scrollToLeft
map $ scrollToRight
map ^ scrollToLeft
map gT previousTab
map gt nextTab
map g0 firstTab
map g$ lastTab
map W moveTabToNewWindow
map < moveTabLeft
map > moveTabRight
map zh scrollLeft
map zl scrollRight
map z<CR> scrollToCenter
map zt scrollToTop
map zz scrollToCenter
map zb scrollToBottom
map m Marks.activateCreateMode
map ` Marks.activateGotoMode
EOF
}

# =============================================================================
# CORE FUNCTIONALITY
# =============================================================================

# Function to show configuration instructions
show_configuration_instructions() {
    local mode="$1"  # "default" or "custom"

    echo ""
    echo "📋 Manual Vimium Configuration Required"
    echo "======================================"
    echo ""
    echo "Since Vimium stores settings in browser's internal storage,"
    echo "you need to manually update the configuration:"
    echo ""
    echo "1. Open Microsoft Edge"
    echo "2. Go to edge://extensions/"
    echo "3. Find Vimium extension"
    echo "4. Click 'Details' → 'Extension options'"
    echo "5. In the 'Custom key mappings' section, paste:"
    echo ""
    echo "----------------------------------------"

    if [[ "$mode" == "custom" ]]; then
        get_custom_keybindings
    else
        get_default_keybindings
    fi

    echo "----------------------------------------"
    echo ""
    echo "6. Click 'Save Options'"
    echo ""
    echo "💡 Tip: You can also access options by typing '?' in any webpage"
    echo "    while Vimium is active, then clicking the 'Options' link."
}

# Function to create backup of current mappings (instruction)
backup_current_mappings() {
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_file="$BACKUP_DIR/vimium-instructions-${timestamp}.txt"

    cat > "$backup_file" << EOF
Vimium Configuration Backup Instructions
Generated: $(date)

To backup your current Vimium settings:
1. Open Microsoft Edge
2. Go to edge://extensions/
3. Find Vimium → Details → Extension options
4. Copy all text from "Custom key mappings" section
5. Save it to a text file

To restore these settings later:
1. Follow steps 1-3 above
2. Paste your saved mappings into "Custom key mappings"
3. Click "Save Options"

Current mode when backup was created: $(cat ~/.dotfiles/vim/.vim/keymap_state 2>/dev/null || echo "unknown")
EOF

    echo "📁 Backup instructions saved to: $backup_file"
}

# =============================================================================
# MAIN INTERFACE
# =============================================================================

# Function to apply keymap mode
apply_keymap_mode() {
    local mode="$1"  # "default" or "custom"

    local app_status=$(detect_app)
    case "$app_status" in
        "edge-not-installed")
            echo "📝 Microsoft Edge not found. Skipping Vimium integration."
            return 0
            ;;
        "vimium-not-installed")
            echo "📝 Vimium extension not installed in Edge. Skipping."
            echo "💡 Install Vimium from: edge://extensions/ → 'Get extensions from Microsoft Store'"
            return 0
            ;;
        "installed")
            echo "🔧 Updating $APP_DISPLAY_NAME settings for $mode mode..."
            ;;
    esac

    # Create backup instructions
    backup_current_mappings

    # Show configuration instructions
    show_configuration_instructions "$mode"

    if [[ "$mode" == "custom" ]]; then
        echo "🎯 $APP_DISPLAY_NAME: CUSTOM (JKLÖ) navigation configuration provided"
    else
        echo "🎯 $APP_DISPLAY_NAME: DEFAULT (HJKL) navigation configuration provided"
    fi

    echo ""
    echo "⚠️  Remember to manually apply these settings in Vimium options!"
    return 0
}

# Function to show current status
show_status() {
    echo "🔧 $APP_DISPLAY_NAME Integration Status"
    echo "========================================"

    local app_status=$(detect_app)
    case "$app_status" in
        "edge-not-installed")
            echo "Microsoft Edge: ❌ Not installed"
            ;;
        "vimium-not-installed")
            echo "Microsoft Edge: ✅ Installed"
            echo "Vimium Extension: ❌ Not installed"
            echo ""
            echo "💡 To install Vimium:"
            echo "   1. Open Edge"
            echo "   2. Go to edge://extensions/"
            echo "   3. Click 'Get extensions from Microsoft Store'"
            echo "   4. Search for 'Vimium' and install"
            ;;
        "installed")
            echo "Microsoft Edge: ✅ Installed"
            echo "Vimium C Extension: ✅ Installed"

            local edge_running=$(is_edge_running)
            echo "Edge currently running: $edge_running"

            # Show all profiles with Vimium C
            echo ""
            echo "Profiles with Vimium C:"
            local vimium_paths=$(find_vimium_storage)
            if [[ -n "$vimium_paths" ]]; then
                while IFS= read -r path_info; do
                    local profile_name="${path_info%%:*}"
                    local path="${path_info#*:}"
                    echo "  $profile_name: $path"
                done <<< "$vimium_paths"
            else
                echo "  None found"
            fi
            ;;
    esac

    echo "Backup directory: $BACKUP_DIR"
    echo "Edge base path: $EDGE_BASE_PATH"

    # Show current system keymap state
    local current_mode=$(cat ~/.dotfiles/vim/.vim/keymap_state 2>/dev/null || echo "unknown")
    echo "System keymap mode: $current_mode"

    # Show backup count
    local backup_count=$(ls "$BACKUP_DIR"/vimium-instructions-*.txt 2>/dev/null | wc -l)
    echo "Configuration backups: $backup_count"

    echo ""
    echo "📋 To check current Vimium configuration:"
    echo "   1. Open any webpage in Edge"
    echo "   2. Press '?' to open Vimium help"
    echo "   3. Click 'Options' to see current mappings"
}

# Function to open Vimium options page
open_options() {
    local app_status=$(detect_app)
    if [[ "$app_status" != "installed" ]]; then
        echo "❌ Vimium not installed in Edge"
        return 1
    fi

    echo "🌐 Opening Vimium options..."
    echo "💡 If Edge doesn't open automatically, go to:"
    echo "   edge://extensions/ → Vimium → Details → Extension options"

    # Try to open Edge extensions page
    if command -v open &> /dev/null; then
        open "edge://extensions/"
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
        backup_current_mappings
        ;;
    "options")
        open_options
        ;;
    *)
        echo "Usage: $0 [default|custom|status|backup|options]"
        echo ""
        echo "Commands:"
        echo "  default  - Show default (HJKL) navigation configuration"
        echo "  custom   - Show custom (JKLÖ) navigation configuration"
        echo "  status   - Show current integration status"
        echo "  backup   - Create backup instructions for current config"
        echo "  options  - Open Vimium options page in Edge"
        echo ""
        echo "Note: Vimium configuration requires manual setup through"
        echo "      the browser extension options page."
        exit 1
        ;;
esac