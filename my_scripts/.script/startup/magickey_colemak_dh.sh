#!/bin/sh
xbindkeys -f /home/qecs/.xbindkeysrc
setxkbmap -layout se -option "caps:swapescape" -option nodeadkeys &&
xmodmap /home/qecs/.script/keyboard_layouts/mod-dh/xmodmap/colemak_dh_iso_us_configured.xmodmap
echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode
xset r rate 250 40
echo "MagicKeys Colemak DH set"
