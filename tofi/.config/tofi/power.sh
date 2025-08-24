#!/bin/bash

choice=$(printf "   Lock\n   Logout\n   Reboot\n   Shutdown" \
    | tofi --prompt-text " " --config ~/.config/tofi/config)

case "$choice" in
    *Lock*)     hyprlock ;;            # call hyprlock directly
    *Logout*)   hyprctl dispatch exit ;;  # Hyprland exit *does* need hyprctl
    *Reboot*)   systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac
