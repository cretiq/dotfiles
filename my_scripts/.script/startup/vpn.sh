#!/bin/sh
nordvpn set killswitch disabled &&
sleep 0.1 &&
nordvpn connect Sweden && 
sleep 0.1 &&
nordvpn set killswitch enabled
