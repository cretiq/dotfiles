#!/bin/bash

# Toggle Windows Terminal pane focus between Voyager (JKLÖ) and Standard (HJKL)
# Voyager: ctrl+j left, ctrl+k down, ctrl+l up, ctrl+vk(192) right (vk 192 = Ö on the Swedish layout)
# Standard: ctrl+h left, ctrl+j down, ctrl+k up, ctrl+l right
# Settings hot-reload on save. The extra MoveFocusRight chord ctrl+alt+o is left alone.

SETTINGS="${1:-/mnt/c/Users/FilipM/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json}"

if [ ! -f "$SETTINGS" ]; then
    echo "Error: File not found at $SETTINGS"
    exit 1
fi

# Each rule edits the "keys" line that follows its action id, so no key is rewritten twice.
retarget() {
    sed -i "/\"id\": \"Terminal.MoveFocus$1\"/{n;s/\"keys\": \"$2\"/\"keys\": \"$3\"/}" "$SETTINGS"
}

if awk '/"id": "Terminal.MoveFocusLeft"/{getline; print}' "$SETTINGS" | grep -q '"ctrl+j"'; then
    retarget Left  'ctrl+j'       'ctrl+h'
    retarget Down  'ctrl+k'       'ctrl+j'
    retarget Up    'ctrl+l'       'ctrl+k'
    retarget Right 'ctrl+vk(192)' 'ctrl+l'
    echo "Windows Terminal: Voyager → Standard"
else
    retarget Left  'ctrl+h' 'ctrl+j'
    retarget Down  'ctrl+j' 'ctrl+k'
    retarget Up    'ctrl+k' 'ctrl+l'
    retarget Right 'ctrl+l' 'ctrl+vk(192)'
    echo "Windows Terminal: Standard → Voyager"
fi
