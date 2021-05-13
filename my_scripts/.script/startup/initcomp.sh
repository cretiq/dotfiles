#!/bin/bash

cd ~/.script/startup/ && 
sudo sh magickey.sh ; 
sh logitech.sh ; 
sh openbox.sh && 
sudo sh diskgrabber.sh ;
xrdb /home/qecs/.Xresources ;
sh vpn.sh
