#!/bin/sh
sudo rmmod hid_apple && sudo modprobe hid_apple
sleep 0.1s
setxkbmap -layout se -option "caps:swapescape" -option nodeadkeys &&
xmodmap -e "keycode  49 = less greater less greater bar brokenbar" &&
xmodmap -e "keycode  94 = section degree section degree notsign notsign"
echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode
echo "MagicKeys set..."