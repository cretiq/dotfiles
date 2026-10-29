#!/bin/bash

# Set all keymaps to Voyager or Standard (non-interactive)
# Usage: set-all-keymap.sh voyager|standard [--no-reload]
# --no-reload: the caller restarts hotkeys-and-remaps.ahk itself (watchers.ahk does, since a copy
# launched from a hidden WSL session failed to replace the running one).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AHK_FILE="$SCRIPT_DIR/hotkeys-and-remaps.ahk"
TOGGLE_ESC="$SCRIPT_DIR/toggle-scripts/bash-toggle-esc.sh"
TOGGLE_HJKL="$SCRIPT_DIR/toggle-scripts/bash-toggle-alt-hjkl.sh"
TOGGLE_WS="$SCRIPT_DIR/toggle-scripts/bash-toggle-window-switcher.sh"
TOGGLE_OBS="$SCRIPT_DIR/toggle-scripts/bash-toggle-obsidian.sh"
TOGGLE_RANGER="$SCRIPT_DIR/toggle-scripts/bash-toggle-ranger.sh"
TOGGLE_WT="$SCRIPT_DIR/toggle-scripts/bash-toggle-windows-terminal.sh"
VIM_TOGGLE="$HOME/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh"
STATUS_ALL="$SCRIPT_DIR/status-scripts/get-all-status.sh"

MODE="${1,,}"
NO_RELOAD=false
[[ "$2" == "--no-reload" ]] && NO_RELOAD=true
if [[ "$MODE" != "voyager" && "$MODE" != "standard" ]]; then
    echo "Usage: $0 voyager|standard"
    exit 1
fi

IFS='|' read -r esc hjkl vim nvim obs ranger ws wt < <("$STATUS_ALL" "$AHK_FILE")

if [[ "$MODE" == "voyager" ]]; then
    FROM="Standard"
else
    FROM="Voyager"
fi

changed=0
ahk_dirty=false
if [[ "$esc" == "$FROM" ]]; then
    "$TOGGLE_ESC" "$AHK_FILE" --no-reload >/dev/null 2>&1
    ahk_dirty=true
    ((changed++))
fi
if [[ "$hjkl" == "$FROM" ]]; then
    "$TOGGLE_HJKL" "$AHK_FILE" --no-reload >/dev/null 2>&1
    ahk_dirty=true
    ((changed++))
fi
if [[ "$vim" == "$FROM" ]]; then
    "$VIM_TOGGLE" toggle >/dev/null 2>&1
    ((changed++))
    # vim-keymap-toggle.sh cascades to obs+ranger managers — refresh state
    # so the if-blocks below see post-cascade values (else they double-flip).
    IFS='|' read -r esc hjkl vim nvim obs ranger ws wt < <("$STATUS_ALL" "$AHK_FILE")
fi
if [[ "$obs" == "$FROM" ]]; then
    "$TOGGLE_OBS" >/dev/null 2>&1
    ((changed++))
fi
if [[ "$ranger" == "$FROM" ]]; then
    "$TOGGLE_RANGER" >/dev/null 2>&1
    ((changed++))
fi
if [[ "$ws" == "$FROM" ]]; then
    "$TOGGLE_WS" >/dev/null 2>&1
    ((changed++))
fi
if [[ "$wt" == "$FROM" ]]; then
    "$TOGGLE_WT" >/dev/null 2>&1
    ((changed++))
fi

# Single AHK reload after all AHK-related toggles
if [[ "$ahk_dirty" == true && "$NO_RELOAD" == false ]]; then
    WIN_PATH=$(wslpath -w "$AHK_FILE")
    "/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey.exe" "$WIN_PATH" >/dev/null 2>&1 &
fi

# Show result
IFS='|' read -r esc hjkl vim nvim obs ranger ws wt < <("$STATUS_ALL" "$AHK_FILE")
echo "All → ${MODE^} ($changed toggled)"
echo "  ESC/CapsLock     [$esc]"
echo "  Alt+HJKL         [$hjkl]"
echo "  Vim              [$vim]"
echo "  Neovim           [$nvim]"
echo "  Obsidian         [$obs]"
echo "  Ranger           [$ranger]"
echo "  Window Switcher  [$ws]"
echo "  Windows Terminal [$wt]"
