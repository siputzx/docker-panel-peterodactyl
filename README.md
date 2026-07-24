# Docker Panel Peterodactyl

This repository provides Docker images for Pterodactyl/Jexactyl eggs.

## Purpose

- Provide ready-to-use runtime images for common egg stacks (Node.js, Python, Go, Bun, Universal).
- Keep images suitable for panel environments (container user, standardized entrypoint, common tooling).
- Offer multi-arch builds (`linux/amd64`, `linux/arm64`) published to GHCR.

This project only provides Docker images for eggs. You can build and maintain your own custom images and eggs if you prefer.

## Image Registry

All images are published under:

`ghcr.io/siputzx/panel:<tag>`

## Image Sizes

The following values are compressed image sizes from GHCR manifests.

### Node.js

| Tag | amd64 | arm64 |
|---|---:|---:|
| `node_18` | 699.5 MiB | 672.9 MiB |
| `node_19` | 628.3 MiB | 596.1 MiB |
| `node_20` | 693.7 MiB | 667.1 MiB |
| `node_21` | 707.6 MiB | 681.4 MiB |
| `node_22` | 702.3 MiB | 675.8 MiB |
| `node_23` | 711.3 MiB | 684.2 MiB |
| `node_24` | 701.8 MiB | 675.3 MiB |
| `node_25` | 696.1 MiB | 669.8 MiB |

### Bun

| Tag | amd64 | arm64 |
|---|---:|---:|
| `bun_1.0` | 716.9 MiB | 683.1 MiB |
| `bun_1.2` | 787.9 MiB | 760.4 MiB |
| `bun_1.3` | 820.5 MiB | 801.5 MiB |
| `bun_1` | 820.5 MiB | 801.5 MiB |
| `bun_latest` | 820.5 MiB | 801.5 MiB |
| `bun_canary` | 820.8 MiB | 801.8 MiB |

### Python

| Tag | amd64 | arm64 |
|---|---:|---:|
| `python_3.11` | 781.2 MiB | 753.8 MiB |
| `python_3.12` | 782.2 MiB | 754.7 MiB |
| `python_3.13` | 784.1 MiB | 756.5 MiB |

### Go

| Tag | amd64 | arm64 |
|---|---:|---:|
| `go_1.20` | 985.3 MiB | 948.7 MiB |
| `go_1.21` | 952.2 MiB | 917.3 MiB |
| `go_1.22` | 950.3 MiB | 914.8 MiB |
| `go_1.23` | 873.4 MiB | 843.1 MiB |
| `go_1.24` | 836.0 MiB | 805.3 MiB |
| `go_1.24.9` | 862.2 MiB | 831.8 MiB |
| `go_1.25` | 817.9 MiB | 788.5 MiB |
| `go_1.25.1` | 844.0 MiB | 814.8 MiB |

### Universal

| Tag | amd64 | arm64 |
|---|---:|---:|
| `debian12_universal` | 1850.8 MiB | 1575.0 MiB |
| `debian13_universal` | 1891.3 MiB | 1625.3 MiB |
| `ubuntu22_universal` | 1549.4 MiB | 1271.2 MiB |
| `ubuntu24_universal` | 1652.1 MiB | 1377.6 MiB |
| `ubuntu25_universal` | 1691.4 MiB | 1417.9 MiB |

## Build and Publish

GitHub Actions workflows build and publish images automatically based on folder changes.

## Notes

- Image size in your local Docker host can be larger than manifest compressed size.
- If you use custom eggs, you can point them to these images or your own images.
