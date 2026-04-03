FROM --platform=$TARGETOS/$TARGETARCH debian:bookworm

LABEL author="siputzx" maintainer="custom@pterodactyl.io"

ARG NODE_MAJOR=22
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        bash \
        build-essential \
        ca-certificates \
        chromium \
        curl \
        dnsutils \
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
        libasound2 \
        libatk-bridge2.0-0 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
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
        libssl-dev \
        lsb-release \
        lsof \
        make \
        mtr-tiny \
        nano \
        neofetch \
        net-tools \
        procps \
        python3 \
        python3-dev \
        python3-pip \
        python3-venv \
        rsync \
        sqlite3 \
        tar \
        tcpdump \
        tini \
        traceroute \
        tree \
        tzdata \
        unzip \
        vim \
        webp \
        whois \
        wget \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g pm2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | gpg --dearmor -o /etc/apt/keyrings/cloudflared.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/cloudflared.gpg] https://pkg.cloudflare.com/cloudflared bookworm main" > /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends cloudflared \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH="$(dpkg --print-architecture)" \
    && if [ "$ARCH" = "amd64" ]; then \
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-linux.gpg; \
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list; \
        apt-get update; \
        apt-get install -y --no-install-recommends google-chrome-stable; \
        rm -rf /var/lib/apt/lists/*; \
    fi

RUN curl -fsSL https://go.dev/VERSION?m=text -o /tmp/go.version \
    && GO_VERSION="$(sed -n '1p' /tmp/go.version)" \
    && ARCH="$(dpkg --print-architecture)" \
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

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/opt/uv sh \
    && ln -sf /opt/uv/uv /usr/local/bin/uv \
    && ln -sf /opt/uv/uvx /usr/local/bin/uvx \
    && uv python install 3.13

RUN curl -fsSL https://bun.sh/install | env BUN_INSTALL=/opt/bun bash \
    && ln -sf /opt/bun/bin/bun /usr/local/bin/bun \
    && ln -sf /opt/bun/bin/bunx /usr/local/bin/bunx

RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
        amd64) DENO_TARGET='x86_64-unknown-linux-gnu' ;; \
        arm64) DENO_TARGET='aarch64-unknown-linux-gnu' ;; \
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac \
    && curl -fsSL "https://github.com/denoland/deno/releases/latest/download/deno-${DENO_TARGET}.zip" -o /tmp/deno.zip \
    && unzip -o /tmp/deno.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/deno \
    && rm -f /tmp/deno.zip

RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --profile default --no-modify-path \
    && mv /root/.cargo /opt/cargo \
    && mv /root/.rustup /opt/rustup \
    && ln -sf /opt/cargo/bin/cargo /usr/local/bin/cargo \
    && ln -sf /opt/cargo/bin/rustc /usr/local/bin/rustc \
    && ln -sf /opt/cargo/bin/rustup /usr/local/bin/rustup

RUN python3 -m pip install --no-cache-dir --break-system-packages -U pip setuptools wheel speedtest-cli

RUN ARCH="$(dpkg --print-architecture)" \
    && case "$ARCH" in \
        amd64) FF_ARCH='linux-amd64' ;; \
        arm64) FF_ARCH='linux-aarch64' ;; \
        *) FF_ARCH='' ;; \
    esac \
    && if [ -n "$FF_ARCH" ]; then \
        FF_URL="$(curl -fsSL https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | jq -r --arg arch "$FF_ARCH" '[.assets[] | select(.name | endswith($arch + ".deb")) | .browser_download_url][0] // empty')"; \
        if [ -n "$FF_URL" ]; then \
            curl -fsSL "$FF_URL" -o /tmp/fastfetch.deb; \
            apt-get update; \
            apt-get install -y --no-install-recommends /tmp/fastfetch.deb; \
            rm -f /tmp/fastfetch.deb; \
            rm -rf /var/lib/apt/lists/*; \
        fi; \
    fi

RUN useradd -m -d /home/container container
STOPSIGNAL SIGINT

ENV PATH="/home/container/.local/bin:/opt/uv:/opt/bun/bin:/opt/cargo/bin:/usr/local/go/bin:${PATH}" \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo

COPY --chown=container:container ./universal/debian/entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./universal/debian/tokoptero-banner.sh /usr/local/bin/tokoptero-banner
COPY --chown=container:container ./universal/debian/tokoptero-shell.sh /etc/profile.d/tokoptero-shell.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/tokoptero-banner /etc/profile.d/tokoptero-shell.sh \
    && mkdir -p /ms-playwright \
    && chown -R container:container /ms-playwright /opt/bun /opt/cargo /opt/rustup /opt/uv

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
