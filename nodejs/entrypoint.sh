#!/bin/bash
cd /home/container || exit 1

# Set timezone
TZ=${TZ:-UTC}
export TZ

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Print Node.js version
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mnode -v\n"
node -v

# Print npm version  
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0mnpm -v\n"
npm -v

# Execute the startup command
printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$STARTUP"
eval ${STARTUP}
