#!/bin/bash -i
init_i # initialize settings for interactive scripts

MUSIC_PATH="$Dir_Data/Media/Music"
MUSIC_PLAYER="mpg123"
MUSIC_LIST=""
OPTION=""
VERBOSE=false

function err_multi {
echo "${c_red}Error: multiple music lists specified${NC}"
}

function usage {
echo -e "Usage: music [-(playlist)|-p|-k] [-v] [-mpg]\n\
Options:\n\
-v|--verbose         Verbose output\n\
-mpg|--mpg123        Use vlc instead of mpg123\n\
-vlc                 Use mpg123 instead of vlc\n\
-k|-s|--kill|--stop  Stop the process and exit\n\
-p|--pause           Pause or resume music playback\n\
\n\
Playlists:\n\
-b|-bwu              Play 'BoyWithUke' music list\n\
-x                   Play 'Ex T-See' music list\n\
-ss                  Play 'Sweet Speeds' music list\n\
-m|-mm               Play 'Money Machine' music list\n\
-j|-jp               Play '日本語の歌' music list\n\
\n\
Hint: if no playlist is specified, the default 'Liked Songs' will play"
}


function check {
verbose "Check if $MUSIC_PLAYER is running"
if ! pgrep "$MUSIC_PLAYER" > /dev/null; then # Check if player is running
    echo -e "${c_red}$MUSIC_PLAYER is not running.${NC}"
    exit
fi
OK
}

function kill_player {
# Checking if the player's process with files in the directory and its subdirectories is running.
verbose "Checking for running $MUSIC_PLAYER processes that playing music…"
if lsof +D "$MUSIC_PATH/" | grep -q "$MUSIC_PLAYER"; then
    verbose "${c_red}Process $MUSIC_PLAYER with files in the directory${NC} $MUSIC_PATH/ ${c_red}has been found.${NC}"
    player_pids=$(lsof +D "$MUSIC_PATH/" | awk '$1=="'"$MUSIC_PLAYER"'" {print $2}')
    for pid in $player_pids; do
        verbose "Killing the process with PID $pid…"
        kill -s SIGTERM $pid
        wait $pid 2>/dev/null
        OK
    done
else
    OK
fi
}

function pause_player {
    verbose "Get the current playback status"
if [[ "$MUSIC_PLAYER" == "vlc" ]]; then
# Get the current playback status
status=$(dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:"org.mpris.MediaPlayer2.Player" string:"PlaybackStatus" | awk '/string/ {print $3}')
    OK
    # Toggle play/pause based on the current status
    if [[ "$status" == "\"Playing\"" ]]; then
    verbose "VLC is playing, pausing now."
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Pause > /dev/null
    else
    verbose "VLC is paused, resuming now."
    dbus-send --print-reply --dest=org.mpris.MediaPlayer2.vlc /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Play > /dev/null
    fi
elif [[ "$MUSIC_PLAYER" == "mpg123" ]]; then
    # Get the current process state
    state=$(ps -p $(pgrep mpg123) -o state=)

    # Toggle play/pause based on the current state
    if [[ "$state" == "T" ]]; then
    verbose "mpg123 is paused, resuming now."
    kill -CONT $(pgrep mpg123)
    else
    verbose "mpg123 is playing, pausing now."
    kill -STOP $(pgrep mpg123)
    fi
fi
OK
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage; exit 0;;
        -mpg|--mpg123) MUSIC_PLAYER=mpg123; shift ;;
        -vlc) MUSIC_PLAYER=vlc; shift ;;
        -p|--pause) OPTION=p; shift ;;
        -s|-k|--kill|--stop) OPTION=s; shift ;;
        -x) if [[ -n $MUSIC_LIST ]]; then err_multi; exit 1; fi; MUSIC_LIST="Ex T-See"; shift ;;
        -ss) if [[ -n $MUSIC_LIST ]]; then err_multi; exit 1; fi; MUSIC_LIST="Sweet Speeds"; shift ;;
        -m|-mm) if [[ -n $MUSIC_LIST ]]; then err_multi; exit 1; fi; MUSIC_LIST="Money Machine"; shift ;;
        -j|-jp) if [[ -n $MUSIC_LIST ]]; then err_multi; exit 1; fi; MUSIC_LIST="日本語の歌"; shift ;;
        -b|-bwu) if [[ -n $MUSIC_LIST ]]; then err_multi; exit 1; fi; MUSIC_LIST="BoyWithUke"; shift ;;
        *) echo -e "${c_red}Unknown parameter passed:${NC} $1"; exit 1 ;;
    esac
done

if [[ "$OPTION" == "p" ]]; then
check; pause_player; exit 1
elif [[ "$OPTION" == "s" ]]; then
check; kill_player; exit 1
fi

# Check for the presence of the player package and suggest to install it if it is not installed.
verbose "Checking if "$MUSIC_PLAYER" package is installed…"
if ! command -v vlc &> /dev/null; then
    verbose "Package "$MUSIC_PLAYER" is not installed. Prompting user for installation…"
    confirm "Do you want to install $MUSIC_PLAYER?" || { verbose "Aborted installation of "$MUSIC_PLAYER" package."; exit 1; }
    verbose "Starting package installation…"
    sudo pacman -S "$MUSIC_PLAYER"
    OK
else
    OK
fi


if [[ -z $MUSIC_LIST ]]; then
    MUSIC_LIST="Liked Songs"
    verbose "No music list specified. Using default: $MUSIC_LIST"

fi

kill_player

if [[ "$MUSIC_PLAYER" == "vlc" ]]; then
    echo "Playing music list: $MUSIC_LIST"
    cvlc --random --no-video -I dummy "$MUSIC_PATH/$MUSIC_LIST/" > /dev/null 2>&1 & exit
elif [[ "$MUSIC_PLAYER" == "mpg123" ]]; then
    echo "Playing music list: $MUSIC_LIST"
    mpg123 -C -Z -v "$MUSIC_PATH/$MUSIC_LIST/"*
else
    echo "Player with the name $MUSIC_PLAYER was not found."
fi
