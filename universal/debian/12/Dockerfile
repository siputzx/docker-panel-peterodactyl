FROM --platform=$TARGETOS/$TARGETARCH debian:12

LABEL author="siputzx" maintainer="custom@pterodactyl.io"

ARG NODE_MAJOR=22
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

COPY ./universal/common/build-base.sh /tmp/build-base.sh
RUN chmod +x /tmp/build-base.sh && /tmp/build-base.sh "$NODE_MAJOR" && rm -f /tmp/build-base.sh

RUN rm -rf /var/lib/apt/lists/*

RUN apt-get update

RUN useradd -m -d /home/container container
STOPSIGNAL SIGINT

ENV LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH="/home/container/.local/bin:/opt/uv:/opt/bun/bin:/opt/cargo/bin:/usr/local/go/bin:${PATH}" \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo

COPY --chown=container:container ./universal/common/entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./universal/common/tokoptero-banner.sh /usr/local/bin/tokoptero-banner
COPY --chown=container:container ./universal/common/tokoptero-shell.sh /etc/profile.d/tokoptero-shell.sh
COPY --chown=container:container ./universal/common/tokoptero-apt.sh /usr/local/bin/tokoptero-apt

RUN chmod +x /entrypoint.sh /usr/local/bin/tokoptero-banner /etc/profile.d/tokoptero-shell.sh /usr/local/bin/tokoptero-apt \
    && mkdir -p /ms-playwright \
    && chown -R container:container /ms-playwright /opt/bun /opt/cargo /opt/rustup /opt/uv

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
