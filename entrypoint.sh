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

# Wings runs the container as the host volume owner, a uid that does not exist in
# /etc/passwd (and /etc is read-only), so shells show "I have no name!". Fix the
# prompt via the writable home instead; whoami cannot be fixed in this setup.
if ! grep -qs TOKOPTERO_PROMPT "${HOME}/.bashrc" 2>/dev/null; then
    {
        echo ''
        echo '# TOKOPTERO_PROMPT'
        echo 'export PS1="\[\e[1;32m\]container@tokoptero\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "'
    } >> "${HOME}/.bashrc" 2>/dev/null || true
fi

STARTUP=${STARTUP:-/bin/bash}
printf "\033[1m\033[33m%s@%s~ \033[0m%s\n" "$(whoami)" "$(hostname)" "$STARTUP"
if [ -n "${SSH_PASSWORD}" ] && [ -x /usr/local/bin/tokoptero-sshd ]; then
    if [ -n "${SSH_PORT}" ] && [ "${SSH_PORT}" != "${SERVER_PORT}" ]; then
        /usr/local/bin/tokoptero-sshd >>"${HOME}/.tokoptero-sshd.log" 2>&1 &
    else
        echo "[tokoptero] SSH dilewati: SSH_PORT kosong atau sama dengan SERVER_PORT"
    fi
fi
exec bash -c "$STARTUP"
