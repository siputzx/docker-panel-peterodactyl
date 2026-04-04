FROM --platform=$TARGETOS/$TARGETARCH ubuntu:22.04

LABEL author="siputzx" maintainer="custom@pterodactyl.io"

ARG NODE_MAJOR=22
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

COPY ./universal/common/build-base.sh /tmp/build-base.sh
RUN chmod +x /tmp/build-base.sh && /tmp/build-base.sh "$NODE_MAJOR" && rm -f /tmp/build-base.sh

RUN apt-get update \
    && CHROMIUM_CANDIDATE="$(apt-cache policy chromium | awk '/Candidate:/ {print $2}')" \
    && if [ -n "$CHROMIUM_CANDIDATE" ] && [ "$CHROMIUM_CANDIDATE" != "(none)" ]; then apt-get install -y --no-install-recommends chromium; fi \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/container container
STOPSIGNAL SIGINT

ENV PATH="/home/container/.local/bin:/opt/uv:/opt/bun/bin:/opt/cargo/bin:/usr/local/go/bin:${PATH}" \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright \
    RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo

COPY --chown=container:container ./universal/common/entrypoint.sh /entrypoint.sh
COPY --chown=container:container ./universal/common/tokoptero-banner.sh /usr/local/bin/tokoptero-banner
COPY --chown=container:container ./universal/common/tokoptero-shell.sh /etc/profile.d/tokoptero-shell.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/tokoptero-banner /etc/profile.d/tokoptero-shell.sh \
    && mkdir -p /ms-playwright \
    && chown -R container:container /ms-playwright /opt/bun /opt/cargo /opt/rustup /opt/uv

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]
