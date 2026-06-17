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

# Primary and secondary connectivity checks
PING_HOST="8.8.8.8"
HTTP_URL="https://www.google.com/generate_204"

# Notification title
NOTIFY_TITLE="Internet connection"

echo "Internet connectivity monitor started."
echo "Check interval set to ${INTERVAL} seconds."

while true; do
    # First check: ICMP ping
    if ping -c 1 -W 2 "$PING_HOST" > /dev/null 2>&1; then
        # Ping OK → internet is considered up, skip secondary check
        sleep "$INTERVAL"
        continue
    fi

    # Second check: only if ping FAILED
    if curl -s --max-time 5 "$HTTP_URL" > /dev/null; then
        # HTTP OK → ping blocked or flaky, but internet exists
        sleep "$INTERVAL"
        continue
    fi

    # Both checks failed → real connectivity issue
    notify-send "$NOTIFY_TITLE" "No internet connection detected."
    s_scream

    sleep "$INTERVAL"
done
