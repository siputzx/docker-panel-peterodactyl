#!/bin/bash
cd /home/container || exit 1

# Use container disk for temp (system /tmp is only 100MB)
export TMPDIR=/home/container/.tmp
export TMP=/home/container/.tmp
export TEMP=/home/container/.tmp
mkdir -p "${TMPDIR}" 2>/dev/null || true

TZ=${TZ:-UTC}
export TZ

INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Auto-detect browser binary, set env vars for Puppeteer/Playwright/Chrome-launcher
for chrome in /usr/bin/chromium /usr/bin/google-chrome /usr/bin/google-chrome-stable; do
    if [ -x "$chrome" ]; then
        export PUPPETEER_EXECUTABLE_PATH="$chrome"
        export PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH="$chrome"
        export PLAYWRIGHT_EXECUTABLE_PATH="$chrome"
        export CHROME_PATH="$chrome"
        export CHROME_BIN="$chrome"
        export CHROME_TEST_BINARY="$chrome"
        break
    fi
done

# Auto-approve native postinstall scripts (canvas, sharp, etc.)
# All commands use timeout to prevent hanging on older versions.
if [ -f /home/container/package.json ]; then
    if command -v pnpm >/dev/null 2>&1; then
        timeout 10 pnpm config set --location project dangerouslyAllowAllBuilds true >/tmp/pnpm-approve.log 2>&1 || true
        timeout 10 pnpm approve-builds --all >>/tmp/pnpm-approve.log 2>&1 || true
    fi
    if command -v bun >/dev/null 2>&1; then
        timeout 10 bun pm trust --all >/tmp/bun-trust.log 2>&1 || true
    fi
fi

printf "\033[1m\033[33m$(whoami)@$(hostname)~ \033[0m%s\n" "$STARTUP"
eval ${STARTUP}
