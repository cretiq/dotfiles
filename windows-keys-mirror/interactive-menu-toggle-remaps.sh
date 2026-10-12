#!/bin/bash

# Interactive Remap Toggle Menu (WSL native)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOGGLE_DIR="$SCRIPT_DIR/toggle-scripts"
STATUS_DIR="$SCRIPT_DIR/status-scripts"
AHK_FILE="$SCRIPT_DIR/hotkeys-and-remaps.ahk"

TOGGLE_ESC="$TOGGLE_DIR/bash-toggle-esc.sh"
TOGGLE_HJKL="$TOGGLE_DIR/bash-toggle-alt-hjkl.sh"
TOGGLE_WS="$TOGGLE_DIR/bash-toggle-window-switcher.sh"
TOGGLE_OBS="$TOGGLE_DIR/bash-toggle-obsidian.sh"
TOGGLE_RANGER="$TOGGLE_DIR/bash-toggle-ranger.sh"
VIM_TOGGLE="$HOME/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh"
STATUS_ALL="$STATUS_DIR/get-all-status.sh"

for f in "$AHK_FILE" "$TOGGLE_ESC" "$TOGGLE_HJKL" "$TOGGLE_WS" "$TOGGLE_OBS" "$TOGGLE_RANGER" "$VIM_TOGGLE" "$STATUS_ALL"; do
    if [[ ! -f "$f" ]]; then
        echo "Error: not found — $f"
        exit 1
    fi
done

reload_ahk() {
    local win_path
    win_path=$(wslpath -w "$AHK_FILE")
    "/mnt/c/Program Files/AutoHotkey/v2/AutoHotkey.exe" "$win_path" >/dev/null 2>&1 &
}

get_statuses() {
    IFS='|' read -r esc_state hjkl_state vim_status nvim_status obsidian_status ranger_status ws_status \
        < <("$STATUS_ALL" "$AHK_FILE")
}

show_statuses() {
    get_statuses
    echo "  ESC/CapsLock     [$esc_state]"
    echo "  Alt+HJKL         [$hjkl_state]"
    echo "  Vim/Neovim       [$vim_status]"
    echo "  Obsidian         [$obsidian_status]"
    echo "  Ranger           [$ranger_status]"
    echo "  Window Switcher  [$ws_status]"
}

# Toggle only if current state != target
set_if_needed() {
    local current="$1" target="$2"
    shift 2
    if [[ "$current" != "$target" ]]; then
        "$@" >/dev/null 2>&1
        return 0
    fi
    return 1
}

while true; do
    clear
    echo ""
    echo "========================================"
    echo "      KEYBOARD REMAP TOGGLE"
    echo "========================================"
    echo ""

    get_statuses

    echo "STATUS:                          Toggle  Set"
    echo "  1. ESC/CapsLock Remap    [$esc_state]       1v  1s"
    echo "  2. Alt+HJKL Navigation   [$hjkl_state]       2v  2s"
    echo "  3. Vim/Neovim Keymap     [$vim_status]       3v  3s"
    echo "  4. Obsidian Keymap       [$obsidian_status]       4v  4s"
    echo "  5. Ranger Keymap         [$ranger_status]       5v  5s"
    echo "  6. Window Switcher       [$ws_status]       6v  6s"
    echo ""
    echo "OPTIONS:"
    echo "  V - Set ALL to Voyager   S - Set ALL to Standard"
    echo "  R - Refresh              Q - Quit"
    echo ""
    read -rp "> " choice

    ahk_dirty=false

    case "${choice,,}" in
        1)  "$TOGGLE_ESC" "$AHK_FILE" --no-reload >/dev/null 2>&1; ahk_dirty=true ;;
        1v) set_if_needed "$esc_state" "Voyager" "$TOGGLE_ESC" "$AHK_FILE" --no-reload && ahk_dirty=true ;;
        1s) set_if_needed "$esc_state" "Standard" "$TOGGLE_ESC" "$AHK_FILE" --no-reload && ahk_dirty=true ;;
        2)  "$TOGGLE_HJKL" "$AHK_FILE" --no-reload >/dev/null 2>&1; ahk_dirty=true ;;
        2v) set_if_needed "$hjkl_state" "Voyager" "$TOGGLE_HJKL" "$AHK_FILE" --no-reload && ahk_dirty=true ;;
        2s) set_if_needed "$hjkl_state" "Standard" "$TOGGLE_HJKL" "$AHK_FILE" --no-reload && ahk_dirty=true ;;
        3)  "$VIM_TOGGLE" toggle >/dev/null 2>&1 ;;
        3v) set_if_needed "$vim_status" "Voyager" "$VIM_TOGGLE" toggle ;;
        3s) set_if_needed "$vim_status" "Standard" "$VIM_TOGGLE" toggle ;;
        4)  "$TOGGLE_OBS" >/dev/null 2>&1 ;;
        4v) set_if_needed "$obsidian_status" "Voyager" "$TOGGLE_OBS" ;;
        4s) set_if_needed "$obsidian_status" "Standard" "$TOGGLE_OBS" ;;
        5)  "$TOGGLE_RANGER" >/dev/null 2>&1 ;;
        5v) set_if_needed "$ranger_status" "Voyager" "$TOGGLE_RANGER" ;;
        5s) set_if_needed "$ranger_status" "Standard" "$TOGGLE_RANGER" ;;
        6)  "$TOGGLE_WS" >/dev/null 2>&1 ;;
        6v) set_if_needed "$ws_status" "Voyager" "$TOGGLE_WS" ;;
        6s) set_if_needed "$ws_status" "Standard" "$TOGGLE_WS" ;;
        v)
            get_statuses
            echo ""
            echo "Setting all to Voyager..."
            set_if_needed "$esc_state" "Voyager" "$TOGGLE_ESC" "$AHK_FILE" --no-reload && ahk_dirty=true
            set_if_needed "$hjkl_state" "Voyager" "$TOGGLE_HJKL" "$AHK_FILE" --no-reload && ahk_dirty=true
            set_if_needed "$vim_status" "Voyager" "$VIM_TOGGLE" toggle
            # vim-keymap-toggle.sh cascades to obs+ranger managers — refresh state
            # so set_if_needed below sees post-cascade values (else double-flip).
            get_statuses
            set_if_needed "$obsidian_status" "Voyager" "$TOGGLE_OBS"
            set_if_needed "$ranger_status" "Voyager" "$TOGGLE_RANGER"
            set_if_needed "$ws_status" "Voyager" "$TOGGLE_WS"
            echo "Done."
            ;;
        s)
            get_statuses
            echo ""
            echo "Setting all to Standard..."
            set_if_needed "$esc_state" "Standard" "$TOGGLE_ESC" "$AHK_FILE" --no-reload && ahk_dirty=true
            set_if_needed "$hjkl_state" "Standard" "$TOGGLE_HJKL" "$AHK_FILE" --no-reload && ahk_dirty=true
            set_if_needed "$vim_status" "Standard" "$VIM_TOGGLE" toggle
            get_statuses
            set_if_needed "$obsidian_status" "Standard" "$TOGGLE_OBS"
            set_if_needed "$ranger_status" "Standard" "$TOGGLE_RANGER"
            set_if_needed "$ws_status" "Standard" "$TOGGLE_WS"
            echo "Done."
            ;;
        r) continue ;;
        q) clear; exit 0 ;;
        *) echo "Invalid option."; sleep 0.5; continue ;;
    esac

    # Single AHK reload after all AHK-related toggles
    [[ "$ahk_dirty" == true ]] && reload_ahk

    echo ""
    show_statuses
    sleep 1
done
