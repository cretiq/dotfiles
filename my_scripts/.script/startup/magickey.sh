setxkbmap -layout se -option nodeadkeys

if echo `lsusb` | grep -q Apple ; then
    xmodmap -e "keycode 49 = section degree section degree notsign notsign"
    xmodmap -e "keycode 94 = less greater less greater bar brokenbar"
    echo 0 > /home/qecs/.script/data/counter
    echo "Apple Keyboard is connected with wire"
else
    xmodmap -e "keycode 49 = less greater less greater bar brokenbar"
    xmodmap -e "keycode 94 = section degree section degree notsign notsign"
    echo 1 > /home/qecs/.script/data/counter
    echo "Apple Keyboard is connected with bluetooth"
fi

sudo echo 1 > /sys/module/hid_apple/parameters/fnmode

xset r rate 250 40
