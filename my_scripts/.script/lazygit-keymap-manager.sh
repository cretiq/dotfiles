#!/bin/bash

# Lazygit Keymap Manager
# Patches only keybinding.universal in ~/.config/lazygit/config.yml
# Preserves gui/theme/os sections.

LAZYGIT_CONFIG_DIR="$HOME/.config/lazygit"
CONFIG_FILE="$LAZYGIT_CONFIG_DIR/config.yml"
BACKUP_DIR="$HOME/.dotfiles/vim/.vim/lazygit-backups"

mkdir -p "$BACKUP_DIR" "$LAZYGIT_CONFIG_DIR"

backup_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        cp "$CONFIG_FILE" "$BACKUP_DIR/config-$(date +%Y%m%d-%H%M%S).bak"
    fi
}

# Patch the 6 keybind values in place. Requires existing keybinding.universal block.
patch_keybinds() {
    local mode="$1"
    local p_prev p_next p_pblk p_nblk p_sup p_sdn mode_label

    if [[ "$mode" == "custom" ]]; then
        p_prev=l; p_next=k; p_pblk=j; p_nblk="ö"; p_sup=L; p_sdn=K
        mode_label="CUSTOM (JKLÖ)"
    else
        p_prev=k; p_next=j; p_pblk=h; p_nblk=l; p_sup=K; p_sdn=J
        mode_label="DEFAULT (HJKL)"
    fi

    backup_config

    # Replace header comment line if present
    sed -i -E "s|^# Mode: .*|# Mode: $mode_label|" "$CONFIG_FILE"

    # Patch the 6 alt keybinds
    sed -i -E \
        -e "s|^(    prevItem-alt:).*|\\1 $p_prev|" \
        -e "s|^(    nextItem-alt:).*|\\1 $p_next|" \
        -e "s|^(    prevBlock-alt:).*|\\1 $p_pblk|" \
        -e "s|^(    nextBlock-alt:).*|\\1 $p_nblk|" \
        -e "s|^(    scrollUpMain-alt1:).*|\\1 $p_sup|" \
        -e "s|^(    scrollDownMain-alt1:).*|\\1 $p_sdn|" \
        "$CONFIG_FILE"

    echo "Lazygit: $mode_label activated"
    echo "Note: Restart Lazygit for changes to take effect"
}

show_status() {
    echo "Lazygit Keymap Status"
    echo "====================="
    echo "Config: $CONFIG_FILE"
    if [[ -f "$CONFIG_FILE" ]]; then
        grep -E "^# Mode:" "$CONFIG_FILE" || echo "# Mode: UNKNOWN"
        grep -E "^    (prevItem|nextItem|prevBlock|nextBlock|scrollUpMain|scrollDownMain)-alt" "$CONFIG_FILE"
    else
        echo "Config file: NOT FOUND"
    fi
}

get_mode() {
    if [[ -f "$CONFIG_FILE" ]] && grep -q "Mode: CUSTOM" "$CONFIG_FILE" 2>/dev/null; then
        echo "Voyager"
    else
        echo "Standard"
    fi
}

case "${1:-status}" in
    default|custom) patch_keybinds "$1" ;;
    status) show_status ;;
    mode) get_mode ;;
    *)
        echo "Usage: $0 [default|custom|status|mode]"
        exit 1
        ;;
esac
