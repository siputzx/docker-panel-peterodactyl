#!/bin/bash

set -euo pipefail

host_name="tokoptero"
kernel="$(uname -r)"
ips="$(hostname -I 2>/dev/null | xargs || true)"
ips="${ips:-127.0.0.1}"
panel_ip="${SERVER_IP:-${INTERNAL_IP:-${ips%% *}}}"
panel_port="${SERVER_PORT:-}"

if [ -z "${panel_ip}" ] || [ "${panel_ip}" = "0.0.0.0" ]; then
    panel_ip="${INTERNAL_IP:-${ips%% *}}"
fi
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

cf_enabled=false
if [ "${CLOUDFLARE_TUNNEL:-false}" = "true" ] || [ "${CLOUDFLARE_TUNNEL:-0}" = "1" ]; then
    cf_enabled=true
fi

resolve_cloudflare_url() {
    if [ "$cf_enabled" != "true" ]; then
        return
    fi

    if [ -n "${CLOUDFLARE_PUBLIC_URL:-}" ]; then
        return
    fi

    for _ in $(seq 1 120); do
        for cf_log in /home/container/cloudflared.log /tmp/cloudflared.log; do
            if [ -f "$cf_log" ]; then
                if [ -n "${CLOUDFLARE_TOKEN:-}" ]; then
                    HOSTNAME="$(grep 'hostname' "$cf_log" | head -n1 | sed -n 's/.*\\"hostname\\":\\"\([^\\]*\)\\",.*/\1/p')"
                    if [ -z "$HOSTNAME" ]; then
                        HOSTNAME="$(grep 'hostname' "$cf_log" | head -n1 | sed -n 's/.*"hostname":"\([^"]*\)".*/\1/p')"
                    fi
                    if [ -n "$HOSTNAME" ]; then
                        CLOUDFLARE_PUBLIC_URL="https://${HOSTNAME}"
                        export CLOUDFLARE_PUBLIC_URL
                        return
                    fi
                else
                    CLOUDFLARE_PUBLIC_URL="$(sed -n 's|.*\(https://[a-zA-Z0-9-]*\.trycloudflare\.com\).*|\1|p' "$cf_log" | head -n1 || true)"
                    if [ -n "${CLOUDFLARE_PUBLIC_URL}" ]; then
                        export CLOUDFLARE_PUBLIC_URL
                        return
                    fi
                fi
            fi
        done
        sleep 0.5
    done
}

cyan=$'\e[1;36m'
green=$'\e[1;32m'
mag=$'\e[1;35m'
white=$'\e[1;37m'
reset=$'\e[0m'

print_logo() {
    local term_cols="${COLUMNS:-80}"

    if command -v tput >/dev/null 2>&1; then
        term_cols="$(tput cols 2>/dev/null || echo "${term_cols}")"
    fi

    if ! [[ "$term_cols" =~ ^[0-9]+$ ]] || [ "$term_cols" -lt 40 ]; then
        term_cols=80
    fi

    if command -v figlet >/dev/null 2>&1; then
        while IFS= read -r line; do
            printf "%b%s%b\n" "$mag" "$line" "$reset"
        done < <(figlet -f small -w "$term_cols" "TOKOPTERO")
    else
        printf "%bTOKOPTERO%b\n" "$mag" "$reset"
    fi
}

printf "\e[H\e[2J"
print_logo
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

resolve_cloudflare_url
if [ "$cf_enabled" = "true" ] && [ -n "${CLOUDFLARE_PUBLIC_URL:-}" ]; then
    printf "${white}Cloudflare URL:${reset} ${cyan}%s${reset}\n" "${CLOUDFLARE_PUBLIC_URL}"
    printf "\n"
fi

printf "${white}Last login:${reset} %s from ${mag}%s${reset}\n" "$(date '+%a %b %d %H:%M:%S %Y')" "$last_login_ip"
