#!/usr/bin/env bash
# Shared helper functions — sourced by all modules

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$HOME/.dotfiles-install.log"

# AUR packages — these must go through paru, not pacman
AUR_PACKAGES=(
    brave-bin
    spotify
    pureref
    wlogout
    hyprlauncher
)

# ── Logging ───────────────────────────────────────────────────────────────────
log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
}

log_info()    { log "INFO"    "$@"; }
log_warn()    { log "WARN"    "$@"; }
log_error()   { log "ERROR"   "$@"; }
log_success() { log "SUCCESS" "$@"; }

# ── Command / package checks ──────────────────────────────────────────────────
command_exists() {
    command -v "$1" &>/dev/null
}

is_installed() {
    pacman -Q "$1" &>/dev/null
}

is_aur() {
    local pkg="$1"
    for aur_pkg in "${AUR_PACKAGES[@]}"; do
        [[ "$aur_pkg" == "$pkg" ]] && return 0
    done
    return 1
}

# ── Package installer ─────────────────────────────────────────────────────────
# Tries pacman first; falls back to paru if pacman -Si fails (not in any repo)
pkg_install() {
    local pkg="$1"

    if is_installed "$pkg"; then
        log_info "SKIP $pkg (already installed)"
        echo "already_installed"
        return 0
    fi

    if is_aur "$pkg"; then
        log_info "AUR $pkg — installing via paru"
        if paru -S --noconfirm --needed --skipreview "$pkg" >> "$LOG_FILE" 2>&1; then
            log_success "INSTALLED (AUR) $pkg"
            echo "installed"
        else
            log_error "FAILED (AUR) $pkg"
            echo "failed"
        fi
        return
    fi

    if pacman -Si "$pkg" &>/dev/null; then
        log_info "REPO $pkg — installing via pacman"
        if sudo pacman -S --noconfirm --needed "$pkg" >> "$LOG_FILE" 2>&1; then
            log_success "INSTALLED $pkg"
            echo "installed"
        else
            log_error "FAILED $pkg"
            echo "failed"
        fi
    else
        # Not in any known repo — try paru as fallback
        log_warn "AUR FALLBACK $pkg — not found in repos, trying paru"
        if paru -S --noconfirm --needed --skipreview "$pkg" >> "$LOG_FILE" 2>&1; then
            log_success "INSTALLED (AUR fallback) $pkg"
            echo "installed"
        else
            log_error "FAILED (AUR fallback) $pkg"
            echo "failed"
        fi
    fi
}

# ── Parse package files ───────────────────────────────────────────────────────
# get_packages_by_tag <file> <tag>
# Returns newline-separated list of package names matching [tag]
get_packages_by_tag() {
    local file="$1"
    local tag="$2"
    grep "^\[$tag\]" "$file" | awk '{print $2}'
}

# get_all_tags <file>
# Returns unique list of tags in file
get_all_tags() {
    local file="$1"
    grep -oP '(?<=\[)[^\]]+' "$file" | sort -u
}

# get_all_packages <file>
# Returns all package names regardless of tag
get_all_packages() {
    local file="$1"
    awk '{print $NF}' "$file"
}
