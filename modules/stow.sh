#!/usr/bin/env bash
# Phase 3d/3e — Stow conflict scan and deployment

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gum-styles.sh"

# Maps: package name (from package lists) → stow directory name
# Only needed where they differ; otherwise package name == stow dir name
declare -A PACKAGE_TO_STOW=(
    [hyprlock]="hypr"
    [hypridle]="hypr"
    [hyprpaper]="hypr"
    [hyprpicker]="hypr"
    [hyprsunset]="hypr"
    [hyprshot]="hypr"
    [hyprtoolkit]="hypr"
    [waybar]="waybar"
    [rofi]="rofi"
    [wlogout]="wlogout"
    [swaync]="swaync"
    [wofi]="wofi"
    [fish]="fish"
    [tmux]="tmux"
    [neovim]="nvim"
    [matugen]="matugen"
)

# Always-stowed packages regardless of tier
ALWAYS_STOW=(bin applications)

# ── Resolve selected packages → unique stow dirs ──────────────────────────────
resolve_stow_dirs() {
    local packages=("$@")
    local -A seen=()
    STOW_DIRS=()

    for pkg in "${packages[@]}"; do
        local dir="${PACKAGE_TO_STOW[$pkg]:-$pkg}"
        # Only add if the stow dir actually exists
        if [[ -d "$DOTFILES_DIR/$dir" ]] && [[ -z "${seen[$dir]:-}" ]]; then
            STOW_DIRS+=("$dir")
            seen[$dir]=1
        fi
    done

    # Always add base packages
    for dir in "${ALWAYS_STOW[@]}"; do
        if [[ -d "$DOTFILES_DIR/$dir" ]] && [[ -z "${seen[$dir]:-}" ]]; then
            STOW_DIRS+=("$dir")
            seen[$dir]=1
        fi
    done

    export STOW_DIRS
}

# ── Pre-flight: back up conflicts ─────────────────────────────────────────────
# Walks each stow package directory and backs up any real files (not symlinks)
# that already exist at the target path — avoids parsing stow's output entirely
stow_preflight() {
    local dirs=("$@")
    BACKED_UP_FILES=()
    local timestamp
    timestamp="$(date '+%Y%m%d%H%M%S')"

    for dir in "${dirs[@]}"; do
        local pkg_dir="$DOTFILES_DIR/$dir"
        [[ -d "$pkg_dir" ]] || continue

        while IFS= read -r src; do
            # Compute where this file would land in $HOME
            local rel="${src#$pkg_dir/}"
            local target="$HOME/$rel"

            # Back up only if a real file (not a symlink) exists at the target
            if [[ -e "$target" && ! -L "$target" ]]; then
                local bak="${target}.bak.${timestamp}"
                mv "$target" "$bak"
                BACKED_UP_FILES+=("$bak")
                log_warn "Backed up: $target → $bak"
            fi
        done < <(find "$pkg_dir" -type f)
    done

    export BACKED_UP_FILES
}

# ── Stow all resolved dirs ────────────────────────────────────────────────────
run_stow() {
    local dirs=("$@")

    for dir in "${dirs[@]}"; do
        gum_spin --title "Stowing $dir..." -- \
            stow --no-folding -d "$DOTFILES_DIR" -t "$HOME" "$dir" >> "$LOG_FILE" 2>&1

        if [[ $? -eq 0 ]]; then
            log_success "Stowed: $dir"
        else
            log_error "Stow failed: $dir"
        fi
    done
}

# ── Terminal config handling ──────────────────────────────────────────────────
stow_terminal() {
    local choice="$1"  # "ghostty" or "kitty"

    if [[ "$choice" == "ghostty" ]]; then
        pkg_install ghostty >> "$LOG_FILE" 2>&1
        # Stow ghostty config if not already in STOW_DIRS
        local already=false
        for d in "${STOW_DIRS[@]}"; do
            [[ "$d" == "ghostty" ]] && already=true
        done
        if [[ "$already" == false ]]; then
            stow_preflight ghostty
            run_stow ghostty
        fi
        log_info "Terminal: ghostty configured"
    else
        log_info "Terminal: kitty selected (installed via must-install, no config stowed)"
    fi
}

# ── Full stow entry point ─────────────────────────────────────────────────────
run_full_stow() {
    local terminal_choice="$1"
    shift
    local packages=("$@")

    resolve_stow_dirs "${packages[@]}"

    gum_spin --title "Scanning for conflicts..." -- sleep 0.5
    stow_preflight "${STOW_DIRS[@]}"

    for dir in "${STOW_DIRS[@]}"; do
        gum_spin --title "Stowing $dir..." -- \
            stow --no-folding -d "$DOTFILES_DIR" -t "$HOME" "$dir" >> "$LOG_FILE" 2>&1
        if [[ $? -eq 0 ]]; then
            log_success "Stowed: $dir"
        else
            log_error "Stow failed: $dir (check $LOG_FILE)"
        fi
    done

    stow_terminal "$terminal_choice"
}
