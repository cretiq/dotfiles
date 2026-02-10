#!/bin/bash

# Ranger Keymap Manager
# Manages dynamic keybinding switching for ranger file manager via rc.conf
# Integrates with the main vim-keymap-toggle.sh system

RANGER_CONFIG="$HOME/.config/ranger/rc.conf"
RANGER_BACKUPS_DIR="$HOME/.dotfiles/vim/.vim/ranger-backups"

# Ensure backup directory exists
mkdir -p "$RANGER_BACKUPS_DIR"

# Function to backup current rc.conf
backup_config() {
    if [[ -f "$RANGER_CONFIG" ]]; then
        local backup_file="$RANGER_BACKUPS_DIR/rc.conf-$(date +%Y%m%d-%H%M%S).bak"
        cp "$RANGER_CONFIG" "$backup_file"
        echo "📁 Backup created: $backup_file"
    fi
}

# Function to apply default HJKL copymaps
apply_default() {
    if [[ ! -f "$RANGER_CONFIG" ]]; then
        echo "📝 Ranger config not found at $RANGER_CONFIG. Skipping."
        return 1
    fi

    backup_config

    sed -i \
        -e 's/^copymap <UP>       .*/copymap <UP>       k/' \
        -e 's/^copymap <DOWN>     .*/copymap <DOWN>     j/' \
        -e 's/^copymap <LEFT>     .*/copymap <LEFT>     h/' \
        -e 's/^copymap <RIGHT>    .*/copymap <RIGHT>    l/' \
        "$RANGER_CONFIG"

    echo "✅ Ranger: DEFAULT (HJKL) keybindings activated"
}

# Function to apply custom JKLÖ copymaps
apply_custom() {
    if [[ ! -f "$RANGER_CONFIG" ]]; then
        echo "📝 Ranger config not found at $RANGER_CONFIG. Skipping."
        return 1
    fi

    backup_config

    sed -i \
        -e 's/^copymap <UP>       .*/copymap <UP>       l/' \
        -e 's/^copymap <DOWN>     .*/copymap <DOWN>     k/' \
        -e 's/^copymap <LEFT>     .*/copymap <LEFT>     j/' \
        -e 's/^copymap <RIGHT>    .*/copymap <RIGHT>    ö/' \
        "$RANGER_CONFIG"

    echo "✅ Ranger: CUSTOM (JKLÖ) keybindings activated"
}

# Function to show current status
show_status() {
    echo "🔧 Ranger Keymap Status"
    echo "========================"

    if [[ ! -f "$RANGER_CONFIG" ]]; then
        echo "Status: Ranger config not found"
        return 0
    fi

    if grep -q "^copymap <LEFT>     j" "$RANGER_CONFIG" 2>/dev/null; then
        echo "Current mode: CUSTOM (JKLÖ)"
    else
        echo "Current mode: DEFAULT (HJKL)"
    fi

    echo ""
    echo "Config: $RANGER_CONFIG"
    echo "Backup directory: $RANGER_BACKUPS_DIR"
}

# Main script logic
case "${1:-status}" in
    "default")
        apply_default
        ;;
    "custom")
        apply_custom
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 [default|custom|status]"
        echo ""
        echo "Commands:"
        echo "  default - Apply default (HJKL) keybindings to ranger"
        echo "  custom  - Apply custom (JKLÖ) keybindings to ranger"
        echo "  status  - Show current ranger keymap status"
        exit 1
        ;;
esac
