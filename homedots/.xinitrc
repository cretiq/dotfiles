#!/bin/sh
#exec startplasma-x11
dbus-update-activation-environment DISPLAY XAUTHORITY
# run openbox on the second screen (they start from 0)
DISPLAY=:0.1 openbox &
# by default openbox will run on the first screen (screen number 0)

#xcompmgr -r 30 -o .35 -f -l -30 -c -t -35 -D 2 -C &
xcompmgr -r 10 -o .60 -f -l -14 -c -t -14 -D 2 -C &
exec openbox-session
