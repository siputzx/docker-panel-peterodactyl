#!/bin/bash

set -euo pipefail

host_name="tokoptero"
kernel="$(uname -r)"
ips="$(hostname -I 2>/dev/null | xargs || true)"
ips="${ips:-127.0.0.1}"
panel_ip="${SERVER_IP:-${INTERNAL_IP:-${ips%% *}}}"
panel_port="${SERVER_PORT:-}"
uptime_short="$(uptime -p 2>/dev/null | sed 's/^up //; s/, / /g' || echo unknown)"
mem_line="$(free -h | awk '/Mem:/ {print $3" of "$2}')"
disk_line="$(df -h /home/container | awk 'NR==2 {print $5" of "$2}')"
rx_today="$(awk -F: '$1 ~ /eth|ens|enp|wlan/ {rx+=$2} END {printf "%.0f MiB", rx/1024/1024}' /proc/net/dev 2>/dev/null || echo '0 MiB')"
cpu_temp="N/A"

if [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    temp_raw="$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)"
    if [ "${temp_raw:-0}" -gt 0 ]; then
        cpu_temp="$((temp_raw / 1000))C"
    fi
fi

cpu_usage() {
    local -a a b
    read -ra a < /proc/stat
    sleep 0.2
    read -ra b < /proc/stat

    local idle1="${a[4]}"
    local idle2="${b[4]}"
    local total1=0
    local total2=0
    local i

    for i in "${a[@]:1:8}"; do
        total1=$((total1 + i))
    done

    for i in "${b[@]:1:8}"; do
        total2=$((total2 + i))
    done

    local total_diff=$((total2 - total1))
    local idle_diff=$((idle2 - idle1))

    if [ "$total_diff" -le 0 ]; then
        echo "0%"
        return
    fi

    local usage=$((100 * (total_diff - idle_diff) / total_diff))
    echo "${usage}%"
}

load_now="$(cpu_usage)"
last_login_ip="${INTERNAL_IP:-127.0.0.1}"

cyan='\033[1;36m'
green='\033[1;32m'
mag='\033[1;35m'
white='\033[1;37m'
reset='\033[0m'

printf "\033c"
printf "${mag} _____ ___  _  ______  ____ _____ _____ ____   ___  ${reset}\n"
printf "${mag}|_   _/ _ \\| |/ / __ \\/ __ \_   _| ____|  _ \\ / _ \\ ${reset}\n"
printf "${mag}  | || | | | ' / |  | |  | || | |  _| | |_) | | | |${reset}\n"
printf "${mag}  | || |_| | . \\ |__| |__| || | | |___|  _ <| |_| |${reset}\n"
printf "${mag}  |_| \\___/|_|\\_\\____/\\____/ |_| |_____|_| \\_\\___/ ${reset}\n"
printf "\n"
printf "${cyan}%s${reset} for ${green}%s${reset} running ${cyan}Debian Linux %s${reset}\n" "Universal Environment" "$host_name" "$kernel"
printf "\n"
printf "${white}Packages:${reset}  Debian stable (bookworm)\n"
if [ -n "$panel_port" ]; then
    printf "${white}IP address:${reset} ${mag}%s:%s${reset}\n" "$panel_ip" "$panel_port"
else
    printf "${white}IP address:${reset} ${mag}%s${reset}\n" "$panel_ip"
fi
printf "\n"
printf "${white}Performance:${reset}\n"
printf "\n"
printf "${green}Load:${reset} %-8s ${green}Up time:${reset} %s\n" "$load_now" "$uptime_short"
printf "${green}Memory usage:${reset} %-14s ${green}Usage of /:${reset} %s\n" "$mem_line" "$disk_line"
printf "${green}CPU temp:${reset} %-4s ${green}RX today:${reset} %s\n" "$cpu_temp" "$rx_today"
printf "\n"
printf "${white}Last login:${reset} %s from ${mag}%s${reset}\n" "$(date '+%a %b %d %H:%M:%S %Y')" "$last_login_ip"
