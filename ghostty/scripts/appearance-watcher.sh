#!/bin/bash
# Watches macOS appearance changes and updates Ghostty split dimming values.
# Ghostty's unfocused-split-opacity/fill don't support dark:/light: syntax,
# so this script bridges the gap by polling AppleInterfaceStyle.

GHOSTTY_CONFIG="$(readlink -f "$HOME/.config/ghostty/config" 2>/dev/null || echo "$HOME/.config/ghostty/config")"
POLL_INTERVAL=5
LAST_MODE=""

get_appearance() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        echo "dark"
    else
        echo "light"
    fi
}

update_config() {
    local mode="$1"
    local opacity fill

    if [[ "$mode" == "dark" ]]; then
        opacity="0.9"
        fill="2a2a2a"
    else
        opacity="0.88"
        fill="cfcfcf"
    fi

    # Avoid sed -i which replaces the file (new inode), breaking Ghostty's file watcher.
    # Write in-place via > to preserve the inode so Ghostty auto-reloads.
    local tmp
    tmp=$(sed "s/^unfocused-split-opacity = .*/unfocused-split-opacity = $opacity/" "$GHOSTTY_CONFIG")
    tmp=$(printf '%s' "$tmp" | sed "s/^unfocused-split-fill = .*/unfocused-split-fill = $fill/")
    printf '%s\n' "$tmp" > "$GHOSTTY_CONFIG"
}

while true; do
    current=$(get_appearance)
    if [[ "$current" != "$LAST_MODE" ]]; then
        update_config "$current"
        LAST_MODE="$current"
    fi
    sleep "$POLL_INTERVAL"
done
