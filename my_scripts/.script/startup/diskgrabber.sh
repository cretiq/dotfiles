#!/bin/sh
diskline=$(sudo fdisk -l | grep -F "2.7T") &&\
diskline=$(echo $diskline | grep -o '^/dev/sd[b-z][0-9]') &&\
echo "Mounting $diskline to /mnt/Media" &&\
sudo mount $diskline /mnt/Media

sleep 0.1s &&\

diskline=$(sudo fdisk -l | grep -F "99.3G") &&\
diskline=$(echo $diskline | grep -o '^/dev/sd[b-z][0-9]') &&\
echo "Mounting $diskline to /mnt/Arch2"
sudo mount $diskline /mnt/Arch2

sleep 0.1s &&\

diskline=$(sudo fdisk -l | grep -F "3.6T") && \
diskline=$(echo $diskline | grep -o '^/dev/sd[b-z][0-9]') && \
echo "Mounting $diskline to /mnt/Gate" && \
sudo mount $diskline /mnt/Gate && \

sleep 0.1s
