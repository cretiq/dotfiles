#!/bin/bash
# Touches only the Voyager (USB vendor 0x3297, product 0x1977); see MAC.md.
set -u
flag="$HOME/.local/share/voyager/auto-off"
modkey="com.apple.keyboard.modifiermapping.12951-6519-0"

case "${1:-status}" in
  off)
    mkdir -p "$(dirname "$flag")" && touch "$flag"
    defaults -currentHost delete -g "$modkey" 2>/dev/null
    hs -c 'hs.reload()' >/dev/null 2>&1
    echo "Hammerspoon Voyager keys: off (reloaded)."
    echo "Modifier Keys: remap deleted. If A, S or D still act swapped, open System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys, pick Voyager, click Restore Defaults."
    ;;
  on)
    rm -f "$flag"
    hs -c 'hs.reload()' >/dev/null 2>&1
    echo "Hammerspoon Voyager keys: on (reloaded)."
    echo "Modifier Keys is not set by this script. In System Settings > Keyboard > Keyboard Shortcuts > Modifier Keys, pick Voyager and set Control Key to Command, Command Key to Control, Option Key to Option."
    ;;
  status)
    if [ -e "$flag" ]; then echo "Hammerspoon Voyager keys: paused ($flag)"; else echo "Hammerspoon Voyager keys: on"; fi
    if defaults -currentHost read -g "$modkey" >/dev/null 2>&1; then echo "Modifier Keys for the Voyager: remapped"; else echo "Modifier Keys for the Voyager: defaults"; fi
    echo -n "Voyager key tap running: "; hs -c 'return tostring(voyagerKeyTap:isEnabled())' 2>&1
    ;;
  *)
    echo "usage: mac-voyager.sh status | off | on" >&2
    exit 2
    ;;
esac
