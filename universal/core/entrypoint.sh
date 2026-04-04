#!/bin/bash
set -e

cd /home/container || exit 1

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 2>/dev/null | awk '{print $(NF-2); exit}')
export INTERNAL_IP

mkdir -p /home/container/.local/bin /home/container/auth /home/container/user/data >/dev/null 2>&1 || true

if command -v uv >/dev/null 2>&1; then
    uv tool install --force yt-dlp >/tmp/yt-dlp-install.log 2>&1 || python3 -m pip install --user --no-cache-dir -U yt-dlp >>/tmp/yt-dlp-install.log 2>&1 || true
else
    python3 -m pip install --user --no-cache-dir -U yt-dlp >/tmp/yt-dlp-install.log 2>&1 || true
fi

if command -v pnpm >/dev/null 2>&1 && [ -f /home/container/package.json ]; then
    pnpm config set --location project dangerouslyAllowAllBuilds true >/tmp/pnpm-approve.log 2>&1 || true
    pnpm approve-builds --all >>/tmp/pnpm-approve.log 2>&1 || true
fi

if [ "${XVFB_ENABLE:-false}" = "true" ] || [ "${XVFB_ENABLE:-0}" = "1" ]; then
    XVFB_DISPLAY=${XVFB_DISPLAY:-:99}
    export XVFB_DISPLAY
    export DISPLAY="$XVFB_DISPLAY"
    if command -v Xvfb >/dev/null 2>&1; then
        nohup Xvfb "$XVFB_DISPLAY" -screen 0 "${XVFB_SCREEN:-1920x1080x24}" -ac +extension RANDR >/tmp/xvfb.log 2>&1 &
        sleep 1
    fi
fi

STARTUP=${STARTUP:-/bin/bash -li}

printf "\033[1m\033[33m%s@tokoptero~ \033[0m%s\n" "$(whoami)" "$STARTUP"

exec /bin/bash -lc "$STARTUP"
