#!/bin/bash
# tokoptero-apt — Persistent package manager for Tokoptero Universal
# Install: tokoptero-apt install neofetch
# Remove:  tokoptero-apt remove neofetch
# List:    tokoptero-apt list
# Update:  tokoptero-apt update

TOKOPTERO_SYS="/home/container/.tokoptero"
PKG_DIR="${TOKOPTERO_SYS}/pkgs"
MANIFEST="${TOKOPTERO_SYS}/manifest"
TMPDIR="${TOKOPTERO_SYS}/.tmp"

die() { echo "✗ $*" >&2; return 1; }

ensure_dirs() {
    mkdir -p "${TOKOPTERO_SYS}/usr/bin" "${TOKOPTERO_SYS}/usr/lib" "${TOKOPTERO_SYS}/usr/local/bin" "${PKG_DIR}" "${TMPDIR}"
}

clean_tmp() {
    rm -rf "${TMPDIR:?}/"* 2>/dev/null || true
}

install_pkg() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt install <package...>"; return 1; }
    ensure_dirs
    clean_tmp
    for pkg in "$@"; do
        echo "→ Installing ${pkg}..."
        cd "${TMPDIR}" || die "cd failed"
        if ! apt download "$pkg" 2>/dev/null; then
            echo "✗ ${pkg}: not found in apt repositories"
            clean_tmp
            continue
        fi
        deb=$(ls "${pkg}"_*.deb 2>/dev/null | head -1)
        if [ -z "$deb" ]; then
            echo "✗ ${pkg}: download failed"
            clean_tmp
            continue
        fi
        dpkg --force-all -x "$deb" "${TOKOPTERO_SYS}/" 2>/dev/null
        cp -af "${TOKOPTERO_SYS}/usr/"* /usr/ 2>/dev/null || true
        cp "$deb" "${PKG_DIR}/"
        echo "${pkg}" >> "${MANIFEST}"
        sort -u "${MANIFEST}" -o "${MANIFEST}"
        clean_tmp
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

search_pkg() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt search <query>"; return 1; }
    apt-cache search "$@" | grep --color=never . || echo "No results for: $*"
}

show_pkg() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt show <package>"; return 1; }
    apt-cache show "$@" || echo "Package not found: $*"
}

upgrade_pkgs() {
    if [ ! -f "${MANIFEST}" ] || [ ! -s "${MANIFEST}" ]; then
        echo "No packages in manifest to upgrade."
        return 0
    fi
    echo "Checking for upgrades..."
    total=$(wc -l < "${MANIFEST}")
    upgraded=0
    while IFS= read -r pkg; do
        [ -z "$pkg" ] && continue
        cur_deb=$(ls "${PKG_DIR}/${pkg}"_*.deb 2>/dev/null | head -1)
        cur_ver=""
        [ -n "$cur_deb" ] && cur_ver=$(dpkg-deb --field "$cur_deb" Version 2>/dev/null || echo "")
        apt_ver=$(apt-cache show "$pkg" 2>/dev/null | grep -m1 "^Version:" | awk '{print $2}')
        if [ -n "$apt_ver" ] && [ "$apt_ver" != "$cur_ver" ]; then
            echo "→ Upgrading ${pkg}: ${cur_ver:-none} → ${apt_ver}"
            clean_tmp
            cd "${TMPDIR}" || continue
            if apt download "$pkg" 2>/dev/null; then
                new_deb=$(ls "${pkg}"_*.deb 2>/dev/null | head -1)
                if [ -n "$new_deb" ]; then
                    dpkg --force-all -x "$new_deb" "${TOKOPTERO_SYS}/" 2>/dev/null
                    cp -af "${TOKOPTERO_SYS}/usr/"* /usr/ 2>/dev/null || true
                    mv "$new_deb" "${PKG_DIR}/"
                    rm -f "$cur_deb"
                    upgraded=$((upgraded + 1))
                    echo "✓ ${pkg} upgraded"
                fi
            fi
            clean_tmp
        fi
    done < "${MANIFEST}"
    echo "Done: ${upgraded}/${total} packages upgraded"
}

source_add() {
    if [ $# -lt 2 ]; then
        echo "Usage: tokoptero-apt source-add <name> <gpg-key-url> <sources-line>"
        echo ""
        echo "Example:"
        echo "  tokoptero-apt source-add docker https://download.docker.com/linux/debian/gpg \\"
        echo "    'deb [signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable'"
        return 1
    fi
    name="$1"
    gpg_url="$2"
    sources_line="$3"
    keyring="/usr/share/keyrings/${name}.gpg"
    sourcelist="/etc/apt/sources.list.d/${name}.list"

    echo "→ Adding source: ${name}"
    mkdir -p /usr/share/keyrings /etc/apt/sources.list.d 2>/dev/null || true
    if curl -fsSL "$gpg_url" | gpg --dearmor -o "$keyring" 2>/dev/null; then
        echo "$sources_line" > "$sourcelist"
        echo "✓ Source ${name} added. Run 'tokoptero-apt update' to refresh."
    else
        echo "✗ Failed to add GPG key from: $gpg_url"
        return 1
    fi
}

install_deb() {
    [ $# -eq 0 ] && { echo "Usage: tokoptero-apt install-deb <url>"; return 1; }
    ensure_dirs
    clean_tmp
    url="$*"
    echo "→ Downloading from ${url}..."
    cd "${TMPDIR}" || die "cd failed"
    filename=$(basename "$url")
    if ! curl -fsSL -o "$filename" "$url" 2>"${TMPDIR}/curl.log"; then
        echo "✗ Download failed: $(cat "${TMPDIR}/curl.log" 2>/dev/null)"
        clean_tmp
        return 1
    fi
    if [[ "$filename" != *.deb ]]; then
        echo "✗ Not a .deb file: $filename"
        clean_tmp
        return 1
    fi
    pkgname=$(dpkg-deb --field "$filename" Package 2>/dev/null || echo "${filename%.deb}")
    echo "→ Extracting ${pkgname}..."
    dpkg -x "$filename" "${TOKOPTERO_SYS}/" 2>/dev/null
    cp -af "${TOKOPTERO_SYS}/usr/"* /usr/ 2>/dev/null || true
    # Auto-symlink binaries in lib/*/bin/ to usr/bin/ (e.g. code-server)
    # Removes wrapper scripts and replaces with direct binary symlinks
    find "${TOKOPTERO_SYS}/usr/lib" -type f -executable -path "*/bin/*" 2>/dev/null | while read -r bin; do
        name=$(basename "$bin")
        rm -f "${TOKOPTERO_SYS}/usr/bin/${name}"
        ln -sf "$bin" "${TOKOPTERO_SYS}/usr/bin/${name}" 2>/dev/null || true
    done
    cp -af "${TOKOPTERO_SYS}/usr/"* /usr/ 2>/dev/null || true
    cp "$filename" "${PKG_DIR}/"
    echo "${pkgname}" >> "${MANIFEST}"
    sort -u "${MANIFEST}" -o "${MANIFEST}"
    clean_tmp
    echo "✓ ${pkgname} installed from external .deb"
}

case "${1:-}" in
    install)     shift; install_pkg "$@" ;;
    install-deb) shift; install_deb "$@" ;;
    remove)      shift; remove_pkg "$@" ;;
    list)        list_pkgs ;;
    update)      update_cache ;;
    search)      shift; search_pkg "$@" ;;
    show)        shift; show_pkg "$@" ;;
    upgrade)     upgrade_pkgs ;;
    source-add)  shift; source_add "$@" ;;
    *)
        echo "tokoptero-apt — Persistent package manager"
        echo ""
        echo "Usage:"
        echo "  tokoptero-apt install <pkg...>      Install package from apt repo (persistent)"
        echo "  tokoptero-apt install-deb <url...>  Install .deb from URL (persistent)"
        echo "  tokoptero-apt remove  <pkg...>      Remove package from manifest"
        echo "  tokoptero-apt list                  List installed packages"
        echo "  tokoptero-apt search <query>        Search apt repositories"
        echo "  tokoptero-apt show  <pkg>           Show package details"
        echo "  tokoptero-apt upgrade               Upgrade all installed packages"
        echo "  tokoptero-apt update                Update apt cache"
        echo "  tokoptero-apt source-add <name> <key-url> <sources-line>"
        echo "                                     Add external repository"
        ;;
esac
