#!/bin/bash
notion-app-nativefier --disable-gpu-vsync & 
sleep 1 &&

known_windows=$(xwininfo -root -children -tree | sed -e 's/^ *//' | grep -E "^0x" | awk '{ print $1 }')

for id in ${known_windows}
do
    class=$(xprop -id $id _OB_APP_CLASS)
    if [[ $class == *"notion"* ]]; then
        echo "HELLO"
        xseticon -id $id ~/.local/share/icons/hicolor/256x256/apps/notion.png
        break
    fi
done

