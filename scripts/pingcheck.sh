#!/bin/bash -i
init_i # initialize settings for interactive scripts

# Default interval in seconds
INTERVAL=90

# Usage function
usage() {
    echo "Usage: $0 [-time SECONDS | -t SECONDS]"
    echo "       SECONDS - interval between connectivity checks (default: 90)"
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -time|-t)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                INTERVAL="$2"
                shift 2
            else
                echo "Error: -time / -t requires a numeric value (seconds)" >&2
                usage
            fi
            ;;
        -*)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Host to check connectivity against (reliable public DNS)
CHECK_HOST="8.8.8.8"

# Notification title
NOTIFY_TITLE="Internet connection"

# Startup message (printed once)
echo "Internet connectivity monitor started."
echo "Check interval set to ${INTERVAL} seconds."

while true; do
    # Ping the host once with a short timeout
    if ! ping -c 1 -W 2 "$CHECK_HOST" > /dev/null 2>&1; then
        # Send desktop notification if no connectivity
        notify-send "$NOTIFY_TITLE" "No internet connection detected."
        s_scream
    fi

    # Wait before next check
    sleep "$INTERVAL"
done
