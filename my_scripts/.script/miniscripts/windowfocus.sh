#!/bin/bash

while [ true ]
do
	FocusApp=`xdotool getwindowfocus getwindowname | sed 's/ .*//'`
	echo $FocusApp
 	if [ "Minecraft" = $FocusApp ]; then
		echo "focus"
	else
		echo "focusloss"
		#xdotool mousemove 1720 2160
		sleep 1s
	fi
done
