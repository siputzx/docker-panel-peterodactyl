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

case "${1:-}" in
    install) shift; install_pkg "$@" ;;
    remove)   shift; remove_pkg "$@" ;;
    list)     list_pkgs ;;
    update)   update_cache ;;
    *)
        echo "tokoptero-apt — Persistent package manager"
        echo ""
        echo "Usage:"
        echo "  tokoptero-apt install <pkg...>  Install package (persists across restarts)"
        echo "  tokoptero-apt remove  <pkg...>  Remove package from manifest"
        echo "  tokoptero-apt list              List installed packages"
        echo "  tokoptero-apt update            Update apt cache"
        ;;
esac
