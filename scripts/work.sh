#! /bin/bash
export LANGUAGE=en_US.UTF-8

if [ -f "/etc/arch-release" ]; then
#     xbindkeys
    /opt/google/chrome/google-chrome %U &
else
    /usr/bin/google-chrome-stable %U &
fi

if pgrep -x "slack" >/dev/null; then
    notify-send "Slack is already running"
else
    slack &
fi

exit
