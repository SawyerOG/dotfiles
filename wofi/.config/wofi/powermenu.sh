#!/bin/sh

options="Lock
Logout
Suspend
Hibernate
Reboot
Shutdown"

chosen="$(echo "$options" | wofi --dmenu --prompt 'Power' --width=20% --height=40% --cache-file=/dev/null)"

case $chosen in
    "Lock") hyprlock ;;
    "Logout") hyprctl dispatch exit ;;
    "Suspend") systemctl suspend ;;
    "Hibernate") systemctl hibernate ;;
    "Reboot") systemctl reboot ;;
    "Shutdown") systemctl poweroff ;;
esac

