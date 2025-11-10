#!/bin/bash
cd /home/container || exit 1

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$STARTUP"
eval ${STARTUP}
