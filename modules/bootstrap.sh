#!/usr/bin/env bash
# Phase 0 — Bootstrap (silent, no gum yet)

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── 0a. Pre-flight ────────────────────────────────────────────────────────────
bootstrap_preflight() {
    # Refuse to run as root
    if [[ "$EUID" -eq 0 ]]; then
        echo "ERROR: Do not run this script as root." >&2
        exit 1
    fi

    # Check internet
    if ! ping -c1 -W3 archlinux.org &>/dev/null; then
        echo "ERROR: No internet connection. Please connect and try again." >&2
        exit 1
    fi

    # Warn if not Arch-based
    if ! command_exists pacman; then
        echo "WARNING: pacman not found. This script is designed for Arch Linux / EndeavourOS." >&2
        echo "Proceeding anyway, but expect failures." >&2
    fi

    log_info "Pre-flight checks passed"
}

# ── 0b. Prerequisites ─────────────────────────────────────────────────────────
bootstrap_prerequisites() {
    echo "Installing prerequisites..."

    for pkg in git gum stow; do
        if ! is_installed "$pkg"; then
            echo "  Installing $pkg..."
            if ! sudo pacman -S --noconfirm --needed "$pkg" >> "$LOG_FILE" 2>&1; then
                echo "ERROR: Failed to install $pkg. Cannot continue." >&2
                exit 1
            fi
        fi
    done

    log_info "Prerequisites ready"
}

# ── 0c. Paru ──────────────────────────────────────────────────────────────────
bootstrap_paru() {
    # Always ensure paru.conf exists with SkipReview regardless of install state
    mkdir -p "$HOME/.config/paru"
    if [[ ! -f "$HOME/.config/paru/paru.conf" ]]; then
        cat > "$HOME/.config/paru/paru.conf" <<'EOF'
[options]
SkipReview
EOF
        log_info "paru.conf created"
    fi

    if command_exists paru; then
        log_info "paru already installed — skipping"
        return 0
    fi

    echo "Installing paru (AUR helper)..."

    if ! is_installed base-devel; then
        sudo pacman -S --noconfirm --needed base-devel >> "$LOG_FILE" 2>&1
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru" >> "$LOG_FILE" 2>&1

    if ! (cd "$tmp_dir/paru" && makepkg -si --noconfirm >> "$LOG_FILE" 2>&1); then
        echo "ERROR: Failed to build paru. Check $LOG_FILE for details." >&2
        rm -rf "$tmp_dir"
        exit 1
    fi

    rm -rf "$tmp_dir"
    log_info "paru installed"

    # Configure paru to skip PKGBUILD review — prevents interactive hangs
    mkdir -p "$HOME/.config/paru"
    cat > "$HOME/.config/paru/paru.conf" <<'EOF'
[options]
SkipReview
EOF
    log_info "paru configured with SkipReview"
}

# ── 0d. Tailscale (optional) ──────────────────────────────────────────────────
bootstrap_tailscale() {
    # gum is available by this point
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/gum-styles.sh"

    if gum_confirm "Set up Tailscale now? (Required for Forgejo access)"; then
        echo "Installing Tailscale..."
        pkg_install tailscale >> "$LOG_FILE" 2>&1
        sudo systemctl enable --now tailscaled >> "$LOG_FILE" 2>&1
        echo "Starting Tailscale — a browser window may open for authentication."
        sudo tailscale up
        echo "Waiting for Tailscale connection..."
        local retries=0
        while ! tailscale status &>/dev/null && [[ $retries -lt 30 ]]; do
            sleep 2
            ((retries++))
        done
        if tailscale status &>/dev/null; then
            log_info "Tailscale connected"
            TAILSCALE_UP=true
        else
            echo "WARNING: Tailscale did not connect in time. Forgejo will be unavailable." >&2
            log_warn "Tailscale connection timed out"
            TAILSCALE_UP=false
        fi
    else
        TAILSCALE_UP=false
        log_info "Tailscale skipped — GitHub only"
    fi

    export TAILSCALE_UP
}

# ── 0e. Dotfiles repo ─────────────────────────────────────────────────────────
bootstrap_repo() {
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/gum-styles.sh"

    # Already running from within the repo
    if git -C "$DOTFILES_DIR" rev-parse --git-dir &>/dev/null; then
        echo "Dotfiles repo detected — pulling latest..."
        git -C "$DOTFILES_DIR" pull >> "$LOG_FILE" 2>&1
        log_info "Repo updated"

        # Ensure both remotes are configured
        if ! git -C "$DOTFILES_DIR" remote get-url origin &>/dev/null; then
            git -C "$DOTFILES_DIR" remote add origin https://github.com/irispsyence/dotfiles.git
        fi
        if [[ "$TAILSCALE_UP" == true ]]; then
            if ! git -C "$DOTFILES_DIR" remote get-url forgejo &>/dev/null; then
                git -C "$DOTFILES_DIR" remote add forgejo http://100.78.168.39:3000/iris/dotfiles.git
            fi
        fi
        return 0
    fi

    # Fresh install — choose remote
    print_header "Clone dotfiles from:"

    local options=("GitHub")
    [[ "$TAILSCALE_UP" == true ]] && options+=("Forgejo")

    local choice
    choice=$(printf '%s\n' "${options[@]}" | gum_choose)

    local repo_url
    case "$choice" in
        GitHub)  repo_url="https://github.com/irispsyence/dotfiles.git" ;;
        Forgejo) repo_url="http://100.78.168.39:3000/iris/dotfiles.git" ;;
    esac

    git clone "$repo_url" "$HOME/dotfiles" >> "$LOG_FILE" 2>&1
    DOTFILES_DIR="$HOME/dotfiles"
    export DOTFILES_DIR

    # Set up both remotes post-clone
    git -C "$DOTFILES_DIR" remote set-url origin https://github.com/irispsyence/dotfiles.git
    if [[ "$TAILSCALE_UP" == true ]]; then
        git -C "$DOTFILES_DIR" remote add forgejo http://100.78.168.39:3000/iris/dotfiles.git 2>/dev/null || true
    fi

    log_info "Repo cloned from $repo_url"
}

# ── 0f. Must-install packages ─────────────────────────────────────────────────
bootstrap_must_install() {
    source "$(dirname "${BASH_SOURCE[0]}")/../lib/gum-styles.sh"

    echo "Installing required packages..."

    # Base must-install list
    local packages=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        packages+=("$line")
    done < "$DOTFILES_DIR/packages/must-install.txt"

    # Append [font] packages from core.txt
    while IFS= read -r pkg; do
        packages+=("$pkg")
    done < <(get_packages_by_tag "$DOTFILES_DIR/packages/core.txt" "font")

    local failed=()
    for pkg in "${packages[@]}"; do
        result=$(pkg_install "$pkg")
        if [[ "$result" == "failed" ]]; then
            failed+=("$pkg")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "ERROR: The following required packages failed to install:" >&2
        printf '  %s\n' "${failed[@]}" >&2
        echo "Check $LOG_FILE for details. Cannot continue." >&2
        exit 1
    fi

    # Post-install setup
    sudo systemctl enable sddm >> "$LOG_FILE" 2>&1
    xdg-user-dirs-update >> "$LOG_FILE" 2>&1

    log_info "Must-install packages complete"
}

# ── Entry point ───────────────────────────────────────────────────────────────
run_bootstrap() {
    bootstrap_preflight
    bootstrap_prerequisites
    bootstrap_paru
    bootstrap_tailscale
    bootstrap_repo
    bootstrap_must_install
}
