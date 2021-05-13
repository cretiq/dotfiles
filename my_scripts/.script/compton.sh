#!/bin/bash
killall compton
sleep 2s
compton --config ~/.config/compton.conf -b
