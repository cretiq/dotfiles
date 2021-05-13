#!bin/sh
setxkbmap -layout se -option "caps:swapescape" -option nodeadkeys &&
sleep 0.1s
xmodmap /home/qecs/.xmodmap
