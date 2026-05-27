#!/bin/bash
# tokoptero-apt — Persistent package manager for Tokoptero Universal
# Install: tokoptero-apt install neofetch
# Remove:  tokoptero-apt remove neofetch
# List:    tokoptero-apt list
# Update:  tokoptero-apt update

TOKOPTERO_SYS="/home/container/tokoptero-sys"
PKG_DIR="${TOKOPTERO_SYS}/pkgs"
MANIFEST="${TOKOPTERO_SYS}/manifest"

die() { echo "✗ $*" >&2; return 1; }

ensure_dirs() {
    mkdir -p "${TOKOPTERO_SYS}/usr/bin" "${TOKOPTERO_SYS}/usr/lib" "${TOKOPTERO_SYS}/usr/local/bin" "${PKG_DIR}"
}

install_pkg() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt install <package...>"; return 1; }
    ensure_dirs
    for pkg in "$@"; do
        echo "→ Installing ${pkg}..."
        tmpdir=$(mktemp -d)
        cd "$tmpdir" || die "cd failed"
        if ! apt download "$pkg" 2>/dev/null; then
            echo "✗ ${pkg}: not found in apt repositories"
            rm -rf "$tmpdir"
            continue
        fi
        deb=$(ls "${pkg}"_*.deb 2>/dev/null | head -1)
        if [ -z "$deb" ]; then
            echo "✗ ${pkg}: download failed"
            rm -rf "$tmpdir"
            continue
        fi
        dpkg --force-all -x "$deb" "${TOKOPTERO_SYS}/" 2>/dev/null
        cp -af "${TOKOPTERO_SYS}/usr/"* /usr/ 2>/dev/null || true
        cp "$deb" "${PKG_DIR}/"
        echo "${pkg}" >> "${MANIFEST}"
        sort -u "${MANIFEST}" -o "${MANIFEST}"
        rm -rf "$tmpdir"
        echo "✓ ${pkg} installed"
    done
}

remove_pkg() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt remove <package...>"; return 1; }
    for pkg in "$@"; do
        sed -i "/^${pkg}$/d" "${MANIFEST}" 2>/dev/null
        rm -f "${PKG_DIR}/${pkg}"_*.deb 2>/dev/null
        echo "✓ ${pkg} removed (restart to fully clear system files)"
    done
}

list_pkgs() {
    if [ -f "${MANIFEST}" ] && [ -s "${MANIFEST}" ]; then
        echo "Installed packages ($(wc -l < "${MANIFEST}")):"
        cat "${MANIFEST}"
    else
        echo "No packages installed yet."
        echo "Try: tokoptero-apt install neofetch"
    fi
}

update_cache() {
    echo "Updating apt cache..."
    apt update
    echo "✓ apt cache updated"
}

install_deb() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt install-deb <url...>"; return 1; }
    ensure_dirs
    for url in "$@"; do
        echo "→ Downloading from ${url}..."
        tmpdir=$(mktemp -d)
        cd "$tmpdir" || die "cd failed"
        filename=$(basename "$url")
        if ! curl -fsSL -o "$filename" "$url"; then
            echo "✗ Download failed: $url"
            rm -rf "$tmpdir"
            continue
        fi
        if [[ "$filename" != *.deb ]]; then
            echo "✗ Not a .deb file: $filename"
            rm -rf "$tmpdir"
            continue
        fi
        pkgname=$(dpkg-deb --field "$filename" Package 2>/dev/null || echo "${filename%.deb}")
        echo "→ Extracting ${pkgname}..."
        dpkg -x "$filename" "${TOKOPTERO_SYS}/" 2>/dev/null
        cp -af "${TOKOPTERO_SYS}/usr/"* /usr/ 2>/dev/null || true
        cp "$filename" "${PKG_DIR}/"
        echo "${pkgname}" >> "${MANIFEST}"
        sort -u "${MANIFEST}" -o "${MANIFEST}"
        rm -rf "$tmpdir"
        echo "✓ ${pkgname} installed from external .deb"
    done
}

case "${1:-}" in
    install)     shift; install_pkg "$@" ;;
    install-deb) shift; install_deb "$@" ;;
    remove)      shift; remove_pkg "$@" ;;
    list)        list_pkgs ;;
    update)      update_cache ;;
    *)
        echo "tokoptero-apt — Persistent package manager"
        echo ""
        echo "Usage:"
        echo "  tokoptero-apt install <pkg...>      Install package from apt repo (persistent)"
        echo "  tokoptero-apt install-deb <url...>  Install .deb from URL (persistent)"
        echo "  tokoptero-apt remove  <pkg...>      Remove package from manifest"
        echo "  tokoptero-apt list                  List installed packages"
        echo "  tokoptero-apt update                Update apt cache"
        ;;
esac
