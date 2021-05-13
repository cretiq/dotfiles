#!/bin/bash

for i in $(seq 10); do
    if xsetwacom list devices | grep -q Wacom; then
        break
    fi
    sleep 1
done

list=$(xsetwacom list devices)
pad=$(echo "${list}" | awk '/pad/{print $9}')
stylus=$(echo "${list}" | xsetwacom list devices | awk '/stylus/{print $9}')

if [ -z "${pad}" ]; then
    exit 0
fi

#echo $stylus
#echo $pad

#xsetwacom set $stylus Button 2 "key z"
#xsetwacom set $stylus Button 3 3
xsetwacom set $stylus Button 1 1
xsetwacom set $stylus Button 2 "key q"
xsetwacom set $stylus Button 3 "key q"

#xsetwacom set $pad Button 1 9
#xsetwacom set $pad Button 2 10
#xsetwacom set $pad Button 3 11


xsetwacom set $stylus MapToOutput "3440x1440+1440+1000"
xsetwacom set $stylus Area 0 0 15200 9500

