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
        opacity="0.85"
        fill="333333"
    else
        opacity="0.8"
        fill="b8b8b8"
    fi

    sed -i '' "s/^unfocused-split-opacity = .*/unfocused-split-opacity = $opacity/" "$GHOSTTY_CONFIG"
    sed -i '' "s/^unfocused-split-fill = .*/unfocused-split-fill = $fill/" "$GHOSTTY_CONFIG"
}

while true; do
    current=$(get_appearance)
    if [[ "$current" != "$LAST_MODE" ]]; then
        update_config "$current"
        LAST_MODE="$current"
    fi
    sleep "$POLL_INTERVAL"
done
