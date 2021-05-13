#!/bin/bash

RUNNING=$(pactl list sinks short | grep RUNNING)
MONITOR=$(pactl list sinks short | grep hdmi | sed 's/\([^a-z]*\).*/\1/')
HEADPHONES=$(pactl list sinks short | grep AMR | sed 's/\([^a-z]*\).*/\1/')
BLUEZ=$(pactl list sinks short | grep bluez | sed 's/\([^a-z]*\).*/\1/') ## Bluetooth audio out (headphones)

if [ "$1" = "monitor" ]; then 
	pacmd set-default-sink $MONITOR
elif [ "$1" = "head" ]; then 
	pacmd set-default-sink $HEADPHONES
else
	if [[ $RUNNING == *"AMR_AMR_USB"* ]]; then
		pacmd set-default-sink $MONITOR
		echo "Switched to monitor"
	elif [[ $RUNNING == *"hdmi"* ]]; then
		pacmd set-default-sink $BLUEZ
		echo "Switched to XMR"
	elif [[ $RUNNING == *"bluez"* ]]; then
		pacmd set-default-sink $HEADPHONES
		echo "Switched to HD650"
	fi
fi
