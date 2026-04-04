#!/bin/bash
set -e

NODE_MAJOR="${1:-22}"

export DEBIAN_FRONTEND=noninteractive

apt-get update \
  && apt-get install -y --no-install-recommends \
    apt-transport-https \
    bash \
    build-essential \
    ca-certificates \
    curl \
    dnsutils \
    composer \
    default-mysql-client \
    ffmpeg \
    fd-find \
    figlet \
    fonts-liberation \
    g++ \
    gcc \
    git \
    gnupg \
    imagemagick \
    iproute2 \
    iputils-ping \
    jq \
    libatk-bridge2.0-0 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libvips-dev \
    libpq-dev \
    libsqlite3-dev \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    libxshmfence1 \
    libcairo2-dev \
    libgif-dev \
    libjpeg-dev \
    libpango1.0-dev \
    librsvg2-dev \
    libssl-dev \
    lsb-release \
    lsof \
    make \
    mtr-tiny \
    nano \
    net-tools \
    php-cli \
    php-curl \
    php-mbstring \
    php-xml \
    postgresql-client \
    procps \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    ruby-full \
    rsync \
    sqlite3 \
    tar \
    tcpdump \
    tini \
    traceroute \
    tree \
    tzdata \
    unzip \
    pkg-config \
    vim \
    webp \
    whois \
    wget \
    xz-utils \
    xvfb \
    zip \
  && rm -rf /var/lib/apt/lists/*

mkdir -p /etc/apt/keyrings \
  && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends nodejs \
  && npm install -g pnpm@latest yarn@latest nodemon pm2 \
  && rm -rf /var/lib/apt/lists/*

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) CF_ARCH='amd64' ;;
  arm64) CF_ARCH='arm64' ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -fsSL "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${CF_ARCH}" -o /usr/local/bin/cloudflared \
  && chmod +x /usr/local/bin/cloudflared

if [ "$ARCH" = "amd64" ]; then
  mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-linux.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*
fi

curl -fsSL https://go.dev/VERSION?m=text -o /tmp/go.version \
  && GO_VERSION="$(sed -n '1p' /tmp/go.version)" \
  && case "$ARCH" in \
      amd64) GO_ARCH='amd64' ;; \
      arm64) GO_ARCH='arm64' ;; \
      *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac \
  && curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tgz \
  && rm -rf /usr/local/go \
  && tar -C /usr/local -xzf /tmp/go.tgz \
  && ln -sf /usr/local/go/bin/go /usr/local/bin/go \
  && ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt \
  && rm -f /tmp/go.tgz /tmp/go.version

curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/opt/uv sh \
  && ln -sf /opt/uv/uv /usr/local/bin/uv \
  && ln -sf /opt/uv/uvx /usr/local/bin/uvx \
  && uv python install 3.13

curl -fsSL https://bun.sh/install | env BUN_INSTALL=/opt/bun bash \
  && ln -sf /opt/bun/bin/bun /usr/local/bin/bun \
  && ln -sf /opt/bun/bin/bunx /usr/local/bin/bunx

case "$ARCH" in
  amd64) DENO_TARGET='x86_64-unknown-linux-gnu' ;;
  arm64) DENO_TARGET='aarch64-unknown-linux-gnu' ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

curl -fsSL "https://github.com/denoland/deno/releases/latest/download/deno-${DENO_TARGET}.zip" -o /tmp/deno.zip \
  && unzip -o /tmp/deno.zip -d /usr/local/bin \
  && chmod +x /usr/local/bin/deno \
  && rm -f /tmp/deno.zip

curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile default --no-modify-path \
  && mv /root/.cargo /opt/cargo \
  && mv /root/.rustup /opt/rustup \
  && ln -sf /opt/cargo/bin/cargo /usr/local/bin/cargo \
  && ln -sf /opt/cargo/bin/rustc /usr/local/bin/rustc \
  && ln -sf /opt/cargo/bin/rustup /usr/local/bin/rustup

python3 -m pip install --no-cache-dir --break-system-packages speedtest-cli

ARCH="$(dpkg --print-architecture)"
case "$ARCH" in
  amd64) FF_ARCH='linux-amd64' ;;
  arm64) FF_ARCH='linux-aarch64' ;;
  *) FF_ARCH='' ;;
esac

if [ -n "$FF_ARCH" ]; then
  FF_URL="$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r --arg arch "$FF_ARCH" '[.assets[] | select(.name | endswith($arch + ".deb")) | .browser_download_url][0] // empty')"
  if [ -n "$FF_URL" ]; then
    curl -fsSL "$FF_URL" -o /tmp/fastfetch.deb \
      && apt-get update \
      && apt-get install -y --no-install-recommends /tmp/fastfetch.deb \
      && rm -f /tmp/fastfetch.deb \
      && rm -rf /var/lib/apt/lists/*
  fi
fi
