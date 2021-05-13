#!/bin/sh

mountedReader=$(mount | grep -o reader)
if [ -n "$mountedReader" ] && [ -n "$1" ]; then
    reader=$(sudo fdisk -l | grep -F "6.74") &&\
    reader=$(echo $reader | grep -o '\/dev\/sd[a-z]') &&\
    echo "Umounting $reader from /mnt/reader"
    sudo umount $reader
elif [ -z "$mountedReader" ]; then
    reader=$(sudo fdisk -l | grep -F "6.74") &&\
    reader=$(echo $reader | grep -o '\/dev\/sd[a-z]') &&\
    echo "Mounting $reader to /mnt/reader"
    sudo mount $reader /mnt/reader
else
    echo "Reader is already mounted..."
fi

