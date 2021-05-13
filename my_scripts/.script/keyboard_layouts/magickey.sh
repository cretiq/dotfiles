#!/bin/sh
sudo rmmod hid_apple && sudo modprobe hid_apple
sleep 0.1s
xbindkeys -f /home/qecs/.xbindkeysrc
setxkbmap -layout se -option "caps:swapescape" -option nodeadkeys &&
xmodmap /home/qecs/.xmodmap
echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode
xset r rate 250 40
echo "MagicKeys set..."
