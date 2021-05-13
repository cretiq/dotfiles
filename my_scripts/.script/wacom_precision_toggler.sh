#!/bin/bash

list=$(xsetwacom list devices)
pad=$(echo "${list}" | awk '/pad/{print $9}')
stylus=$(echo "${list}" | xsetwacom list devices | awk '/stylus/{print $9}')
area=$(xsetwacom get ${stylus} area | awk '{print $1}')

if [ ${area} -ne -20000 ]; then
    echo "Precision Mode: ON"
    xsetwacom set $stylus Area -20000 -6000 15200 9500
    xsetwacom set $stylus MapToOutput "3440x1440+1000+750"
else 
    echo "Precision Mode: OFF"
    xsetwacom set $stylus Area 0 0 15200 9500
    xsetwacom set $stylus MapToOutput "3440x1440+1440+1000"
fi
