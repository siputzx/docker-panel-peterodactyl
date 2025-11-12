FROM --platform=$TARGETOS/$TARGETARCH golang:1.20-bookworm
LABEL author="siputzx" maintainer="custom@pterodactyl.io"

RUN useradd -m -d /home/container container
STOPSIGNAL SIGINT

RUN apt update \
    && apt -y install \
        ffmpeg iproute2 git sqlite3 libsqlite3-dev python3 python3-dev \
        ca-certificates dnsutils tzdata zip tar curl build-essential libtool \
        iputils-ping libnss3 tini gnupg wget imagemagick libcairo2-dev \
        libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev chromium \
        libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 \
        libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
        fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 \
        libatk1.0-0 libcups2 libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 \
        libnspr4 libnss3 libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p --mode=0755 /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg -o /usr/share/keyrings/cloudflare-public-v2.gpg \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' > /etc/apt/sources.list.d/cloudflared.list \
    && apt update && apt -y install cloudflared && apt clean && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    GO111MODULE=on \
    CGO_ENABLED=1 \
    GOOS=linux

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY --chown=container:container ../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
