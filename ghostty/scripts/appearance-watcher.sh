#!/bin/bash
# Watches macOS appearance changes and updates Ghostty split dimming + tmux theme.
# Polls AppleInterfaceStyle every 5s.

# Resolve symlink — macOS readlink doesn't support -f, use python fallback
GHOSTTY_CONFIG="$(python3 -c "import os; print(os.path.realpath(os.path.expanduser('~/.config/ghostty/config')))" 2>/dev/null || echo "$HOME/.config/ghostty/config")"
POLL_INTERVAL=5
LAST_MODE=""

get_appearance() {
    if defaults read -g AppleInterfaceStyle &>/dev/null; then
        echo "dark"
    else
        echo "light"
    fi
}

update_ghostty() {
    local mode="$1"
    local opacity fill

    if [[ "$mode" == "dark" ]]; then
        opacity="0.8"
        fill="181825"  # catppuccin mocha mantle
    else
        opacity="0.8"
        fill="e6e9ef"  # catppuccin latte mantle
    fi

    sed -i '' "s/^unfocused-split-opacity = .*/unfocused-split-opacity = $opacity/" "$GHOSTTY_CONFIG"
    sed -i '' "s/^unfocused-split-fill = .*/unfocused-split-fill = $fill/" "$GHOSTTY_CONFIG"
}

update_tmux() {
    local mode="$1"
    local flavor

    if [[ "$mode" == "dark" ]]; then
        flavor="mocha"
    else
        flavor="latte"
    fi

    # Only update if tmux server is running
    if tmux list-sessions &>/dev/null; then
        tmux set -g @catppuccin_flavor "$flavor"
        # Unset @thm_* so catppuccin re-applies (theme files use -o flag)
        for v in bg fg crust mantle rosewater flamingo pink mauve red maroon peach yellow green teal sky sapphire blue lavender overlay_0 overlay_1 overlay_2 surface_0 surface_1 surface_2 subtext_0 subtext_1; do
            tmux set -gu @thm_$v
        done
        tmux run-shell "$HOME/.config/tmux/plugins/tmux/catppuccin.tmux"
    fi
}

update_config() {
    local mode="$1"
    update_ghostty "$mode"
    update_tmux "$mode"
}

while true; do
    current=$(get_appearance)
    if [[ "$current" != "$LAST_MODE" ]]; then
        update_config "$current"
        LAST_MODE="$current"
    fi
    sleep "$POLL_INTERVAL"
done
