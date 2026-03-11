#!/bin/bash
# Wrapper called by udev (runs as root) - triggers the toggle script as the user
UID_DANIEL=$(id -u daniel)
sudo -u daniel DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID_DANIEL/bus" \
  /home/daniel/scripts/touchpad/toggle-touchpad.sh &
