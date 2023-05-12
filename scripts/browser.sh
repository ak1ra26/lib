#!/bin/bash

# Set the browser command based on the given argument
if [[ "$1" == "-cryptochrome" ]]; then
    browser="/usr/bin/google-chrome-stable --profile-directory='Profile 1'"
elif [[ "$1" == "-ffb" ]]; then
    browser="firefox-beta"
    find ~/.cache/mozilla/firefox/*.default-beta/cache2/entries/ -type f -mtime +7 -delete

else
    browser="firefox"
#     rm -rf ~/.cache/mozilla/firefox/*.default-release/cache2/* # зробити окремий скрипт чи аліас чистки.
    "$browser" > /dev/null 2>&1 & # тимчасове рішення, щоб не закривати firefox-beta замість firefox.
    exit
fi

# Check if the browser is running
if pgrep -f "$browser" > /dev/null; then
    # Get the PID of the browser process
    pid=$(pgrep -f "$browser")

    # Close the browser using wmctrl
    wmctrl -i -c $(wmctrl -lp | grep -E "^[^:]*\s+$pid\s+" | awk '{print $1}')

    # Wait for the browser process to end
    counter=0
    while pgrep -f "$browser" > /dev/null; do
        sleep 1
        ((counter++))
        if ((counter >= 3)); then
            xdotool search --pid $pid windowkill
            break
        fi
    done
fi

# Launch the browser and suppress output
"$browser" > /dev/null 2>&1 &
