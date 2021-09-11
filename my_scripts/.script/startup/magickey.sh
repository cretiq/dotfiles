#!/bin/sh
#sudo rmmod hid_apple && sudo modprobe hid_apple
#sleep 0.1s
#setxkbmap -layout se -option "caps:swapescape" -option nodeadkeys &&
#xbindkeys -f /home/qecs/.xbindkeysrc

setxkbmap -layout se -option nodeadkeys

value=`cat /home/qecs/.script/data/counter`

if [[ $value == "1" ]]; then
    xmodmap -e "keycode 49 = section degree section degree notsign notsign"
    xmodmap -e "keycode 94 = less greater less greater bar brokenbar"
    echo 0 | tee /home/qecs/.script/data/counter
else
    xmodmap -e "keycode 49 = less greater less greater bar brokenbar"
    xmodmap -e "keycode 94 = section degree section degree notsign notsign"
    echo 1 | tee /home/qecs/.script/data/counter
fi

echo 1 | sudo tee /sys/module/hid_apple/parameters/fnmode

xset r rate 250 40
