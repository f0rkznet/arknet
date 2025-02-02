#!/bin/bash

API_URL="https://api.steamcmd.net/v1/info/2430930"
APP_MANIFEST="/data/steamapps/appmanifest_2430930.acf"
CHECK_INTERVAL=300  # Check every 5 minutes (adjust as needed)

check_update_pid=$!

timestamp () {
  date +"%Y-%m-%d %H:%M:%S,%3N"
}

shutdown() {
    echo "$(date +"%Y-%m-%d %H:%M:%S,%3N") INFO: Received SIGTERM, shutting down gracefully..."
    SHUTDOWN=true
}

# Extract the installed build ID from the manifest file
get_installed_buildid() {
    grep -oP '"buildid"\s+"\K[0-9]+' "$APP_MANIFEST" 2>/dev/null
}

trap shutdown TERM INT

while [[ "$SHUTDOWN" == false ]]; do
    echo "Checking for updates..."
    INSTALLED_BUILD_ID=$(get_installed_buildid)
    CURRENT_BUILD_ID=$(curl -s "$API_URL" | jq -r '.data["2430930"].depots.branches.public.buildid')

    if [[ -z "$CURRENT_BUILD_ID" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S,%3N") Error: Unable to fetch build ID."
    elif [[ -z "$INSTALLED_BUILD_ID" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S,%3N") Error: Unable to read installed build ID from $APP_MANIFEST."
    elif [[ "$CURRENT_BUILD_ID" != "$INSTALLED_BUILD_ID" ]]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S,%3N") New version detected! Installed: $INSTALLED_BUILD_ID, Available: $CURRENT_BUILD_ID"
        docker restart $(docker ps | grep -v update-check | grep -v CONTAINER\ ID | awk {'print $1'})
    else
        echo "No changes detected. Installed version: $INSTALLED_BUILD_ID"
    fi

    # Break early if shutdown signal received
    for ((i=0; i<CHECK_INTERVAL; i++)); do
        [[ "$SHUTDOWN" == true ]] && break
        sleep 1
    done
done
