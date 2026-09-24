# Docker Panel Pterodactyl

Production-ready Docker images for [Pterodactyl](https://pterodactyl.io) / [Jexactyl](https://jexactyl.com) eggs.

Built for panel hosting: a `container` user, a standardized entrypoint, optional SSH access, and the
common tooling bots and web apps expect (ffmpeg, git, sqlite3, build tooling, browsers).

## Image Registry

All images are published to GitHub Container Registry:

```
ghcr.io/siputzx/panel:<tag>
```

Images are multi-arch (`linux/amd64`, `linux/arm64`).

## Available Images

| Family | Tags | Use case |
|---|---|---|
| **Node.js** | `node_18`, `node_19`, `node_20`, `node_21`, `node_22`, `node_23`, `node_24`, `node_25`, `node_26` | JavaScript / TypeScript bots and APIs |
| **Bun** | `bun_1.0`, `bun_1.2`, `bun_1.3`, `bun_1`, `bun_latest`, `bun_canary` | Bun runtimes |
| **Python** | `python_3.11`, `python_3.12`, `python_3.13`, `python_3.14` | Python bots and scripts |
| **Go** | `go_1.20` … `go_1.26` | Compiled Go services |
| **Universal** | `debian12_universal`, `debian13_universal`, `ubuntu22_universal`, `ubuntu24_universal`, `ubuntu25_universal` | General purpose: Node + Bun + Go + Python in a single image |

## Image Sizes

Sizes are the **uncompressed size on disk** as reported by `docker images`, i.e. how much space each
image takes on a node once pulled. Compressed download sizes are roughly 3-4x smaller.

### Node.js

| Tag | Size |
|---|---:|
| `node_18` | 2.74 GB |
| `node_19` | 2.44 GB |
| `node_20` | 2.74 GB |
| `node_21` | 2.77 GB |
| `node_22` | 2.75 GB |
| `node_23` | 2.79 GB |
| `node_24` | 2.75 GB |
| `node_25` | 2.77 GB |
| `node_26` | 2.76 GB |

### Bun

| Tag | Size |
|---|---:|
| `bun_1.0` | ~2.9 GB |
| `bun_1.2` | 2.98 GB |
| `bun_1.3` | ~3.0 GB |
| `bun_1` | ~3.1 GB |
| `bun_latest` | 3.16 GB |
| `bun_canary` | ~3.1 GB |

### Python

| Tag | Size |
|---|---:|
| `python_3.11` | 2.97 GB |
| `python_3.12` | 2.98 GB |
| `python_3.13` | 2.97 GB |
| `python_3.14` | 2.98 GB |

### Go

| Tag | Size |
|---|---:|
| `go_1.20` | ~3.1 GB |
| `go_1.21` | ~3.1 GB |
| `go_1.22` | ~3.1 GB |
| `go_1.23` | ~3.0 GB |
| `go_1.24` | ~3.0 GB |
| `go_1.24.9` | ~3.1 GB |
| `go_1.25` | 3.20 GB |
| `go_1.25.1` | 3.31 GB |
| `go_1.26` | 3.20 GB |

### Universal

| Tag | Size |
|---|---:|
| `debian12_universal` | 9.19 GB |
| `debian13_universal` | 9.36 GB |
| `ubuntu22_universal` | 8.77 GB |
| `ubuntu24_universal` | 8.92 GB |
| `ubuntu25_universal` | 8.92 GB |

## What's Inside

Every image ships with:

- A non-privileged `container` user and a `/home/container` working directory.
- A standardized entrypoint that prepares `TMPDIR`, detects the browser binary, and runs the egg
  startup command.
- Common tooling: `ffmpeg`, `git`, `sqlite3`, `curl`, `iproute2`, a C toolchain (for native npm
  modules), and a Chromium build for headless automation.
- **Optional SSH access**: when the egg variable `SSH_PASSWORD` is set, a lightweight SSH daemon
  starts on the server's second allocation port (`SSH_PORT`). When `SSH_PASSWORD` is empty, SSH stays
  disabled.
- An interactive banner on the panel console and on SSH logins.

## Using These Images In An Egg

Point the egg's `docker_images` at the tags you want, for example:

```json
{
  "node 20": "ghcr.io/siputzx/panel:node_20",
  "node 22": "ghcr.io/siputzx/panel:node_22",
  "ubuntu 24 universal": "ghcr.io/siputzx/panel:ubuntu24_universal"
}
```

The SSH feature uses two egg variables:

| Variable | Purpose | Editable by user |
|---|---|---|
| `SSH_PASSWORD` | Set to enable SSH. Empty disables it. | Yes |
| `SSH_PORT` | Port SSH listens on (from an extra allocation). | No |

## Build Locally

```bash
docker build -f nodejs/22/Dockerfile -t panel:node_22 .
docker build -f universal/debian/12/Dockerfile -t panel:debian12_universal .
```

Each Dockerfile is self-contained and uses the repository root as its build context.

## Automated Builds

GitHub Actions rebuilds and publishes images when the relevant files change:

| Workflow | Trigger paths |
|---|---|
| `nodejs.yml` | `nodejs/**`, `entrypoint.sh` |
| `bun.yml` | `bun/**`, `entrypoint.sh` |
| `python.yml` | `python/**`, `entrypoint.sh` |
| `golang.yml` | `golang/**`, `entrypoint.sh` |
| `universal.yml` | `universal/**` |

## Notes

- The container user is intentionally **not pinned with `USER`**: Wings runs each container as the
  owner of that server's volume, and that uid differs per node. Pinning a uid in the image makes the
  container unable to write its own volume when Wings does not override it.
- Image size on a node equals the uncompressed size above; the compressed size only affects how long
  the initial `docker pull` takes.
- This repository only provides images. You can build and maintain your own images and eggs instead.

## License

MIT
