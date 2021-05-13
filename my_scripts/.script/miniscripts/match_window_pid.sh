#!/bin/sh

known_windows=$(xwininfo -root -children -tree | sed -e 's/^ *//' | grep -E "^0x" | awk '{ print $1 }')
notion=''

for id in ${known_windows}
do
    class=$(xprop -id $id _OB_APP_CLASS)
    if [[ $class == *"Notion"* ]]; then
        xseticon -id $id ~/.local/share/icons/hicolor/512x512/notion512.png
        echo $id
        echo $class 
        break
    fi
done
