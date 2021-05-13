#!/bin/sh
echo "Closing in 2.."
sleep 1s
echo "Closing in 1.."
sleep 1s
kill -9 $PPID
