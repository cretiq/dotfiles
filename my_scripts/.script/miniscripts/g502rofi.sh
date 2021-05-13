#!/bin/bash

window_class=$(xprop -id `xdotool getactivewindow` | grep _NET_WM_STATE_FULLSCREEN)

if [ -z "$window_class" ]; then
	rofi -combi-modi window,drun -show combi
fi