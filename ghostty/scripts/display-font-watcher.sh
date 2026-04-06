#!/bin/bash
# Watches display count and adjusts Ghostty font size.
# Larger font when external monitor connected, laptop font when solo.
# Known limitation: clamshell mode (lid closed + external) reads as 1 display.

GHOSTTY_CONFIG="$(readlink -f "$HOME/.config/ghostty/config" 2>/dev/null || echo "$HOME/.config/ghostty/config")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POLL_INTERVAL=5
LAST_COUNT=""
LAPTOP_FONT=17
EXTERNAL_FONT=20

get_display_count() {
    if [[ -x "$SCRIPT_DIR/display-count" ]]; then
        "$SCRIPT_DIR/display-count"
    else
        system_profiler SPDisplaysDataType 2>/dev/null | grep -c "Resolution:"
    fi
}

update_font_size() {
    local count="$1"
    local target_size

    if [[ "$count" -gt 1 ]]; then
        target_size="$EXTERNAL_FONT"
    else
        target_size="$LAPTOP_FONT"
    fi

    sed -i '' "s/^font-size = .*/font-size = $target_size/" "$GHOSTTY_CONFIG"
    pkill -SIGUSR2 ghostty 2>/dev/null
    osascript -e 'tell application "Ghostty"
        repeat with t in every terminal
            perform action "set_font_size:'"$target_size"'" on t
        end repeat
    end tell' 2>/dev/null
}

while true; do
    current=$(get_display_count)
    if [[ "$current" != "$LAST_COUNT" ]]; then
        update_font_size "$current"
        LAST_COUNT="$current"
    fi
    sleep "$POLL_INTERVAL"
done
