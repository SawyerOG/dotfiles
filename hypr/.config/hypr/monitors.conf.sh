#!/usr/bin/env bash

# Detect if laptop internal screen (eDP) exists
if ls /sys/class/drm | grep -q "^card[0-9]-eDP"; then
    # Laptop mode
    echo "monitor=eDP-1,preferred,0x0,1"
    #echo "monitor=HDMI-A-1,preferred,1920x0,auto"
else
    # Desktop mode
    echo "monitor=HDMI-A-1,preferred,0x0,auto"
    echo "monitor=DP-1,preferred,0x-1440,auto"
    echo "monitor=DVI-I-2,preferred,-1920x0,auto"
fi
