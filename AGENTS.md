# Docker Panel Peterodactyl — Agent Guide

## What this is

Docker images for [Pterodactyl/Jexactyl](https://pterodactyl.io/) game panel eggs. Each stack directory builds multi-arch (`linux/amd64`, `linux/arm64`) images published to `ghcr.io/siputzx/panel:<tag>`.

## Architecture

```
nodejs/{version}/Dockerfile     ← Node.js runtime images (18–26)
bun/{version}/Dockerfile        ← Bun runtime images (1.0–1.3, latest, canary)
python/{version}/Dockerfile     ← Python runtime images (3.11–3.14)
golang/{version}/Dockerfile     ← Go runtime images (1.20–1.26)
universal/{distro}/{version}/Dockerfile  ← Tokoptero "universal" images (all runtimes)
universal/common/               ← Shared assets for universal images
entrypoint.sh                   ← Entrypoint shared by nodejs/bun/python/golang
```

## Image tags

Format: `{stack}_{version}` — e.g. `node_22`, `go_1.24`, `python_3.12`, `bun_1`, `debian12_universal`, `ubuntu24_universal`.

## Build (CI)

Five independent GitHub Actions workflows, one per stack. Triggered by pushes to `main` or `master` AND changes under that stack's directory (or its own workflow file).

| Workflow | Trigger path | Matrix |
|---|---|---|
| `nodejs.yml` | `nodejs/**` | `node-version: [26,25,24,23,22,21,20,19,18]` |
| `bun.yml` | `bun/**` | `bun-version: [1.0,1.2,1.3,1,latest,canary]` |
| `python.yml` | `python/**` | `python-version: [3.11,3.12,3.13,3.14]` |
| `golang.yml` | `golang/**` | `go-version: ["1.20","1.21","1.22","1.23","1.24","1.24.9","1.25","1.25.1","1.26"]` |
| `universal.yml` | `universal/**` | 5 images across Debian 12/13 and Ubuntu 22.04/24.04/25.10 |

Workflow steps are identical across all:
1. `actions/checkout@v4`
2. Validate Dockerfile exists
3. `docker/setup-qemu-action@v3` (needed for arm64 builds)
4. `docker/setup-buildx-action@v3`
5. `docker/login-action@v3` against GHCR
6. `docker/build-push-action@v5` with `context: .`, multi-platform, GHA cache

All workflows set `concurrency` with `cancel-in-progress: true` and `fail-fast: false`.

**Cache scopes** are stack-specific: `nodejs{version}`, `bun{version}`, `python{version}`, `golang{version}`, `universal{tag}`.

**Build output**: `provenance: false`, `sbom: false`.

Manual trigger via `workflow_dispatch` is enabled on all workflows.

## Image conventions (shared across all non-universal stacks)

- **Base image**: Official language image (e.g. `node:22-bookworm-slim`, `python:3.12-bookworm`, `golang:1.24-bookworm`, `oven/bun:1`)
- **Multi-arch**: `FROM --platform=$TARGETOS/$TARGETARCH ...`
- **User**: `container` with home `/home/container`, shell `/bin/bash`
- **Init**: `tini` via `ENTRYPOINT ["/usr/bin/tini", "-g", "--"]`
- **Entrypoint**: `CMD ["/entrypoint.sh"]` (shared `entrypoint.sh` at repo root)
- **Working dir**: `WORKDIR /home/container`
- **Stop signal**: `STOPSIGNAL SIGINT`
- **Common apt packages**: ffmpeg, git, sqlite3, python3, build-essential, iproute2, ca-certificates, curl, wget, tini, imagemagick, browser libs (libx11, libgtk-3, libnss3, etc.), fonts-liberation
- **Chromium**: Installed via `apt-cache show` loop (tries `chromium` then `chromium-browser`)
- **Cloudflared**: Installed from Cloudflare's apt repo
- **Puppeteer/Playwright**: `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true`, `PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1`, `PLAYWRIGHT_BROWSERS_PATH=/ms-playwright`. Directory `/ms-playwright` created and owned by `container`.
- **No `.dockerignore`** files exist.

### Per-stack differences

| Stack | Additional steps | Env vars |
|---|---|---|
| **nodejs** (18–26) | `npm install -g corepack` + `corepack enable` + `corepack prepare pnpm@latest --activate` (NOT on node:25) | `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium` |
| **golang** | None extra | `GO111MODULE=on`, `CGO_ENABLED=1`, `GOOS=linux`, `PUPPETEER_EXECUTABLE_PATH=/usr/bin/` (note: trailing slash, different from others) |
| **python** | `pip install --no-cache-dir --upgrade pip setuptools wheel` | `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium` |
| **bun** | None extra | `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium` |

> **Hot path**: When adding a new version, the pattern is: create `{stack}/{version}/Dockerfile` and add the version to the workflow matrix. No other config needed.

## ⚠️ KNOWN INKONSISTENSI & GOTCHAS (baca ini sebelum bikin update)

### Inkonsistensi formatting Dockerfile

| Stack | `FROM` line style | Spasi antar directive | Trailing newline | Layout apt packages |
|---|---|---|---|---|
| **nodejs** (18–23,25–26) | `FROM\t--platform=...` (tab) | Ada blankline antar blok | ❌ 18–24 **tidak ada** newline di akhir file; ✅ 25–26 **ada** | Satu package per baris |
| **nodejs** (24) | `FROM --platform=...` (spasi) — **SATU-SATUNYA** node yg beda | Sama | ❌ Tidak ada | Satu package per baris |
| **golang** (semua) | `FROM --platform=...` (spasi) | Ada blankline | ✅ Ada | **Compact** — 4+ package per baris `\` |
| **python** | `FROM\t--platform=...` (tab) | ❌ **Tidak ada** blankline antar RUN (demet) | ✅ Ada | Satu package per baris |
| **bun** | `FROM\t--platform=...` (tab) | **Double-space** pada RUN/LABEL/ENV (pake leading whitespace ekstra) | ✅ Ada | Satu package per baris |
| **universal** | `FROM --platform=...` (spasi) | Ada blankline | ✅ Ada | Pake `build-base.sh` |

**Kesimpulan**: Setiap stack punya gaya formatting sendiri. Jangan copy-paste beda stack — selalu copy dari version tetangga di stack yg SAMA.

### Node.js

- **Node 19**: package `node:19-bullseye-slim` (bukan bookworm). Ini satu-satunya node yg pake bullseye.
- **Node 24**: FROM line-nya `FROM --platform=...` (1 spasi). Semua node lain pake `FROM\t--platform=...` (tab). Kalau bikin update ke node 24, perhatiin ini.
- **Node 25**: **TIDAK ada** corepack/pnpm. Node 18-24 dan 26 semua pake, tapi 25 enggak. Mungkin karena Node 25 ship built-in corepack? Tapi kalau nambah node 27+, jangan asumsi ikutin node 25 — ikutin node 26.
- **Node 26**: `FROM node:26.2-bookworm-slim` (pinned patch version). Lainnya pake `node:25-bookworm-slim` (tanpa patch). Kalau nambah node 27+, cek official image-nya butuh pinned version atau nggak.
- **Trailing newline**: Node 18–24 ga punya newline di akhir file. Node 25–26 punya. Kalau edit file node existing, jangan nambahin newline — ntar dirty diff. Tapi kalau bikin file baru, pake newline.
- **APT package count**: Tepat 55 package (hitung `\` lines). Kalau ada yg beda, dicek ulang.

### Golang

- **PUPPETEER_EXECUTABLE_PATH=/usr/bin/** (trailing slash, **tanpa** `chromium`!). Stack lain pake `/usr/bin/chromium`. Ini kemungkinan bug — tapi entrypoint auto-override di runtime, jadi mungkin sengaja. JANGAN di-"fix" tanpa konfirmasi.
- **Format cloudflared compact**: `apt update && apt -y install cloudflared && apt clean && rm -rf` — satu line. Stack lain pake multi-line dengan `\`.
- **Format apt packages compact**: 4+ package per baris `\`, bukan satu-per-baris seperti node/python/bun.
- **Patch version**: `golang/1.24.9/` dan `golang/1.25.1/` adalah directory sendiri dengan matrix entry sendiri. File Dockerfile-nya IDENTIK dengan versi mayor (hanya FROM tag yg beda).
- **Trailing newline**: Semua Go file ada newline — consistent.

### Python

- **Tidak ada blankline antar directive**: `LABEL` → `RUN useradd` → `STOPSIGNAL` → `RUN apt` — semua dempet tanpa baris kosong. Berbeda dari node/go yang pake blankline separator.
- **Python 3.14 vs 3.11-3.13**: Order `pip install --no-cache-dir --upgrade pip setuptools wheel` BERBEDA. Di 3.11-3.13 ada sebelum `RUN mkdir -p /ms-playwright`, di 3.14 ada setelahnya. Waktu bikin python 3.15+, liat mana yg bener.
- **Python 3.14**: Total 85 lines vs 3.13: 84 lines (karena ada extra line dari reordering).
- **Tidak ada python3/python3-dev** di apt packages (udah include di base image python).
- **Tidak ada corepack/pnpm** — Python-specific.

### Bun

- **Semua file Bun** pake leading double-spaces: `RUN         apt`, `LABEL       author`, `ENV         PUPPETEER...`. Jangan normalize ke single-space — ntar semua file dirty.
- **Tidak ada corepack/pnpm** — Bun pake package manager bawaan.
- **Bun 1.0 dan 1.2**: Tetap dipertahankan meskipun versi lama (matrix: `['1.0', '1.2', '1.3', '1', 'latest', 'canary']`).
- **Tag `bun_1`** = latest 1.x (sama kayak `bun_1.3`).

### Universal

- **Chromium install**: BERBEDA per distro:
  - **Debian 12/13**: Pake `apt-cache show` loop (sama kayak node/python/bun/golang)
  - **Ubuntu 22.04/24.04**: Pake `software-properties-common` + `add-apt-repository ppa:xtradeb/apps` + `apt-get install chromium`
  - **Ubuntu 25.10**: Sama kayak 22.04/24.04 tapi ada tambahan comment `# Google Chrome is installed by build-base.sh for amd64` di atas chromium block
- **Google Chrome**: Hanya diinstall di amd64 (build-base.sh pake conditional `[ "$ARCH" = "amd64" ]`)
- **build-base.sh** install versi LATEST dari Go, Deno, Rust — jadi image universal bisa beda tiap build.
- **Passwordless sudo**: `echo "container ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/container`
- **System dirs world-writable**: `chmod 777 /usr/bin /usr/lib /usr/lib64 /usr/share /usr/local` — VPS-like behavior.

### Entrypoint

- **Ada DUA entrypoint berbeda**:
  - `/entrypoint.sh` (root) — dipake nodejs/bun/python/golang → `TMPDIR=/home/container/.tmp`, auto-detect browser, `eval ${STARTUP}`
  - `universal/common/entrypoint.sh` — dipake universal → `TMPDIR=/home/container/.tokoptero/tmp`, yt-dlp install, Xvfb handler, `pnpm approve-builds`, `exec /bin/bash -lc "$STARTUP"`
- **Perbedaan kritis**: Universal entrypoint pake `exec /bin/bash -lc "$STARTUP"` (login shell), sementara root entrypoint pake `eval ${STARTUP}` (bukan subshell).

## Entrypoint (`entrypoint.sh`)

The root `entrypoint.sh` is shared by nodejs, bun, python, and golang stacks:

1. `cd /home/container`
2. Sets `TMPDIR=/home/container/.tmp` (system `/tmp` is only 100 MB in panel containers)
3. Sets `TZ` (defaults to UTC)
4. Resolves `INTERNAL_IP` via `ip route get 1`
5. Auto-detects browser binary (`chromium` > `google-chrome` > `google-chrome-stable`) and sets `PUPPETEER_EXECUTABLE_PATH`, `PLAYWRIGHT_*`, `CHROME_PATH`, `CHROME_BIN`, `CHROME_TEST_BINARY`
6. Prints startup message and runs `eval ${STARTUP}`

## Universal ("tokoptero") stack

Purpose-built VPS-like environment with all runtimes pre-installed. Different from other stacks:

- **Base**: `debian:12`, `debian:13`, `ubuntu:22.04`, `ubuntu:24.04`, `ubuntu:25.10`
- **Build**: Uses `universal/common/build-base.sh` instead of inline RUN commands
- **Shared assets** (in `universal/common/`):
  - `build-base.sh` — Installs everything (Go, Node.js, Python, Bun, Deno, Rust, PHP 8.5 via Sury, Ruby, uv, pnpm, yarn, nodemon, pm2, composer, google-chrome-stable, cloudflared, fastfetch)
  - `entrypoint.sh` — Different from root one. Uses `.tokoptero/` namespace for persistent state. Installs yt-dlp at start. Handles Xvfb. Runs `pnpm approve-builds`.
  - `tokoptero-apt.sh` — Persistent package manager (installs .deb to `/home/container/.tokoptero/`, survives container restart)
  - `tokoptero-banner.sh` — Rich MOTD with system stats, Cloudflare Tunnel URL resolution
  - `tokoptero-shell.sh` — Profile script with aliases (`ll`, `la`, `l`, `install`) and PS1
- **`build-base.sh` key installation steps**: Node.js via NodeSource, Go via `go.dev`, uv via astral.sh, Bun via bun.sh, Deno via GitHub releases, Rust via rustup, cloudflared binary, Google Chrome on amd64, fastfetch via GitHub releases
- **Permissions model**: Container user gets passwordless sudo. Key system dirs (`/usr/bin`, `/usr/lib`, `/usr/share`, `/usr/local`) are world-writable (chmod 777).

## Container runtime notes

- Startup is driven by the `STARTUP` environment variable (set by the panel)
- The entrypoint does not set `STARTUP`; it defaults to `/bin/bash -li` if undefined
- For browser automation, Chromium is pre-installed; Puppeteer/Playwright downloads are skipped

## Adding a new image version

1. Create `{stack}/{version}/Dockerfile` following the pattern of an EXISTING version IN THE SAME STACK — jangan copy dari stack lain (formatting bisa beda)
2. Add the version to the corresponding workflow's matrix
3. PR to `main` or `master` — CI auto-builds on push to those branches when files under `{stack}/` change

### Checklist pas nambah version baru

- [ ] Format FROM line konsisten dengan version tetangga (cekTAB vs space)
- [ ] Corepack/pnpm: node 18-24,26 ada; node 25 tidak. Untuk node 27+ ikutin node 26.
- [ ] Base image tag: cek kalo butuh `bookworm-slim` atau patch version (lihat node 26: `26.2`)
- [ ] Trailing newline: baru pake `\n`, jangan lupa
- [ ] Matrix entry di workflow: format nomor konsisten (string vs number — cek golang pake string `"1.20"`, nodejs pake number `23`)
