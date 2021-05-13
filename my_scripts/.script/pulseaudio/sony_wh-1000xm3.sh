#!/bin/bash
active_profiles=$(pacmd list-cards | grep 'active profile')
is_xm3=$(pacmd list-sinks | grep WH-1000XM3)

if [[ -n "$is_xm3" ]]; then
    echo "Sony's XM3 are already connected"
else
    bluetoothctl connect CC:98:8B:1B:CB:51
    echo "Sony's XM3 are now connected..."
    sleep 1;
fi
if [[ $active_profiles == *"a2dp_sink"* ]]; then
    echo "a2dp_sink is already active"
else
    pactl set-card-profile bluez_card.CC_98_8B_1B_CB_51 a2dp_sink
    echo "a2dp_sink is now active..."
fi
