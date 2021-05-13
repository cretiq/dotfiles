#!/bin/bash

## Modifier
MOD=5

## Current Sink(output source)
SINK=$(pactl list sinks short | grep bluez | grep -v apps | sed -e 's,^\([0-9][0-9]*\)[^0-9].*,\1,' | head -1)

## Current Volume
#NOW=$(pactl list sinks | grep -i -A 8 'RUNNING' | grep -i -A 8 'alsa_output.' |  grep Volume | head -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')

#if [ -z  $NOW ]; then ## If alsa output is none, then XMR is probably connected (bluetooth headphones)
    NOW=$(pactl list sinks | grep -i -A 8 'RUNNING' | grep -i -A 8 'bluez' |  grep Volume | head -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
#fi

echo $SINK
echo $NOW
echo $MOD

## Check if in parameter is raise or not
if [ "$1" = "raise" ]; then
    ## Lower than or equal to 95%: Raise 5% as usual
    if [[ $NOW -le 95 ]]; then
        pactl set-sink-volume $SINK +${MOD}%
    ## Greater than 95%: Raise 100 - $currentVolume (remainder to 100%), up to max 100%.
    elif [[ $NOW -gt 95 ]] && [[ $NOW -lt 100 ]]; then
        pactl set-sink-volume $SINK +$(expr 100 - $NOW)%
    fi
else
    pactl set-sink-volume $SINK -${MOD}%
fi

## Get current volume to notify volnoti
#NOW=$(pactl list sinks | grep -i -A 8 'RUNNING' | grep -i -A 8 'alsa_output.' |  grep Volume | head -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')

#if [ -z  $NOW ]; then ## If alsa output is none, then XMR is probably connected (bluetooth headphones)
    NOW=$(pactl list sinks | grep -i -A 8 'RUNNING' | grep -i -A 8 'bluez' |  grep Volume | head -n 1 | sed -e 's,.* \([0-9][0-9]*\)%.*,\1,')
#fi

volnoti-show $NOW
echo SINK: $SINK
echo Volume: $NOW
