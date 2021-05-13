#!/bin/bash

clip=$(xclip -o)

urxvt -e mpv $clip

if [ "$1" = "up" ]; then
	xdotool search --class mpv windowmove 100 1270 windowsize 704 700
elif [ "$1" = "down" ]; then
	xdotool search --class mpv windowmove 100 1470 windowsize 704 700
fi
