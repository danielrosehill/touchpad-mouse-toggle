#!/bin/bash
# Toggle touchpad based on whether an external mouse is connected.
# Called by udev rule on mouse add/remove events, or manually.

# Small delay to let KWin register the device change
sleep 1

# Ensure we have access to the session bus
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

# Find all devices and classify them
TOUCHPAD_DEVS=""
MOUSE_COUNT=0

for dev in $(dbus-send --session --print-reply --dest=org.kde.KWin \
  /org/kde/KWin/InputDevice \
  org.freedesktop.DBus.Properties.Get \
  string:'org.kde.KWin.InputDeviceManager' \
  string:'devicesSysNames' 2>/dev/null | grep -oP 'event\d+'); do

  name=$(dbus-send --session --print-reply --dest=org.kde.KWin \
    "/org/kde/KWin/InputDevice/$dev" \
    org.freedesktop.DBus.Properties.Get \
    string:'org.kde.KWin.InputDevice' string:'name' 2>/dev/null | grep 'string "' | tail -1 | sed 's/.*string "//;s/"//')

  is_pointer=$(dbus-send --session --print-reply --dest=org.kde.KWin \
    "/org/kde/KWin/InputDevice/$dev" \
    org.freedesktop.DBus.Properties.Get \
    string:'org.kde.KWin.InputDevice' string:'pointer' 2>/dev/null | grep -c 'boolean true')

  is_touchpad=$(dbus-send --session --print-reply --dest=org.kde.KWin \
    "/org/kde/KWin/InputDevice/$dev" \
    org.freedesktop.DBus.Properties.Get \
    string:'org.kde.KWin.InputDevice' string:'touchpad' 2>/dev/null | grep -c 'boolean true')

  # Track touchpad devices dynamically
  if [ "$is_touchpad" = "1" ]; then
    TOUCHPAD_DEVS="$TOUCHPAD_DEVS $dev"
    continue
  fi

  # Count external mice (pointer, not touchpad, not virtual/fake/trackpoint)
  if [ "$is_pointer" = "1" ]; then
    if ! echo "$name" | grep -qiE 'virtual|fake|trackpoint|XTEST'; then
      MOUSE_COUNT=$((MOUSE_COUNT + 1))
      logger "toggle-touchpad: found external mouse: $name ($dev)"
    fi
  fi
done

if [ "$MOUSE_COUNT" -gt 0 ]; then
  ENABLE="false"
else
  ENABLE="true"
fi

# Set enabled state on all touchpad devices
for tp in $TOUCHPAD_DEVS; do
  dbus-send --session --print-reply --dest=org.kde.KWin \
    "/org/kde/KWin/InputDevice/$tp" \
    org.freedesktop.DBus.Properties.Set \
    string:'org.kde.KWin.InputDevice' string:'enabled' \
    "variant:boolean:$ENABLE" 2>/dev/null
done

logger "toggle-touchpad: external mice=$MOUSE_COUNT, touchpad enabled=$ENABLE (touchpads:$TOUCHPAD_DEVS)"
echo "External mice: $MOUSE_COUNT, touchpad enabled: $ENABLE (touchpads:$TOUCHPAD_DEVS)"
