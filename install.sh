#!/usr/bin/env bash
# Hyprland dotfiles install script
# https://github.com/irispsyence/dotfiles

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/lib/helpers.sh"

# ── TTY detection ─────────────────────────────────────────────────────────────
# gum requires a proper terminal — if we're in a raw TTY, bootstrap silently
# then instruct the user to launch Hyprland and re-run from kitty
is_tty() {
    [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]
}

if is_tty; then
    echo "Detected TTY — running silent bootstrap..."
    echo ""

    # Install prerequisites silently
    for pkg in git gum stow; do
        if ! is_installed "$pkg"; then
            echo "  Installing $pkg..."
            sudo pacman -S --noconfirm --needed "$pkg"
        fi
    done

    # Install paru if missing
    if ! command_exists paru; then
        echo "  Installing paru..."
        sudo pacman -S --noconfirm --needed base-devel
        tmp="$(mktemp -d)"
        git clone https://aur.archlinux.org/paru.git "$tmp/paru"
        (cd "$tmp/paru" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi

    # Install kitty and hyprland so we have a terminal and compositor
    for pkg in kitty hyprland; do
        if ! is_installed "$pkg"; then
            echo "  Installing $pkg..."
            sudo pacman -S --noconfirm --needed "$pkg"
        fi
    done

    echo ""
    echo "Bootstrap complete."
    echo ""
    echo "Next steps:"
    echo "  1. Run: Hyprland"
    echo "  2. Open kitty (Super + Return or kitty in the Hyprland session)"
    echo "  3. Run: cd ~/dotfiles && ./install.sh"
    echo ""
    exit 0
fi

source "$DOTFILES_DIR/lib/gum-styles.sh"
source "$DOTFILES_DIR/modules/bootstrap.sh"
source "$DOTFILES_DIR/modules/packages.sh"
source "$DOTFILES_DIR/modules/stow.sh"
source "$DOTFILES_DIR/modules/paths.sh"
source "$DOTFILES_DIR/modules/services.sh"
source "$DOTFILES_DIR/modules/shell.sh"

# ── Shared state ──────────────────────────────────────────────────────────────
INSTALL_TIER=""
TERMINAL_CHOICE=""
SELECTED_CORE_PACKAGES=()
SELECTED_ADDITIONAL_PACKAGES=()
ALL_SELECTED_PACKAGES=()

# ── Phase 1 — Welcome ─────────────────────────────────────────────────────────
phase_welcome() {
    clear
    print_banner
    echo
    gum style --foreground "$COLOR_DIM" "  User: $USER    Host: $(hostname)    $(uname -r)"
    echo

    INSTALL_TIER=$(gum_choose \
        "⚡  Opinionated — full personal setup, no menus" \
        "🔧  Custom      — interactive step-by-step" \
        "📦  Minimal     — Hyprland + UI + fonts only" \
        "👁  Dry Run     — preview all actions, install nothing")

    # Extract tier keyword
    case "$INSTALL_TIER" in
        "⚡"*) INSTALL_TIER="opinionated" ;;
        "🔧"*) INSTALL_TIER="custom"      ;;
        "📦"*) INSTALL_TIER="minimal"     ;;
        "👁"*) INSTALL_TIER="dryrun"      ;;
    esac

    export INSTALL_TIER
}

# ── Phase 2 — Custom flow (steps 1-6) ────────────────────────────────────────
phase_custom() {
    local STEP=1

    while [[ $STEP -le 6 ]]; do
        clear
        case $STEP in
        1)
            print_step 1 6 "Terminal Choice"
            echo
            print_info "kitty is pre-installed as a fallback regardless of choice."
            echo
            local choice
            choice=$(gum_choose "ghostty" "kitty")
            TERMINAL_CHOICE="$choice"
            ((STEP++))
            ;;
        2)
            print_step 2 6 "Main Packages"
            echo
            select_core_packages 2
            echo
            if gum_confirm "Continue to additional packages?"; then
                ((STEP++))
            else
                ((STEP--))
            fi
            ;;
        3)
            print_step 3 6 "Additional Packages"
            echo
            select_additional_packages 3
            echo
            if gum_confirm "Continue?"; then
                ((STEP++))
            else
                ((STEP--))
            fi
            ;;
        4)
            print_step 4 6 "Scripts"
            echo
            print_info "Scripts found in bin/ — select which to install:"
            echo
            local available_scripts=()
            mapfile -t available_scripts < <(find "$DOTFILES_DIR/bin/.local/bin" -type f -executable 2>/dev/null | xargs -I{} basename {})

            if [[ ${#available_scripts[@]} -eq 0 ]]; then
                print_info "No scripts found."
                sleep 1
                ((STEP++))
            else
                local selected_scripts
                mapfile -t selected_scripts < <(printf '%s\n' "${available_scripts[@]}" | \
                    gum_multiselect --selected "$(IFS=,; echo "${available_scripts[*]}")")
                SELECTED_SCRIPTS=("${selected_scripts[@]}")
                export SELECTED_SCRIPTS
                echo
                if gum_confirm "Continue?"; then
                    ((STEP++))
                else
                    ((STEP--))
                fi
            fi
            ;;
        5)
            print_step 5 6 "Path Replacement"
            echo
            print_info "Hardcoded home paths in configs will be replaced with /home/$USER/"
            echo
            replace_paths true  # preview
            if gum_confirm "Apply path replacement?"; then
                PATH_REPLACEMENT_SKIPPED=false
            else
                PATH_REPLACEMENT_SKIPPED=true
                gum style --foreground "$COLOR_ACCENT" "  Skipped — flagged as manual follow-up."
            fi
            export PATH_REPLACEMENT_SKIPPED
            sleep 1
            if gum_confirm "Continue to confirmation?"; then
                ((STEP++))
            else
                ((STEP--))
            fi
            ;;
        6)
            print_step 6 6 "Confirm"
            echo
            print_header "Install summary"
            echo
            gum style --foreground "$COLOR_FG" "  Terminal:   $TERMINAL_CHOICE"
            gum style --foreground "$COLOR_FG" "  Core pkgs:  ${#SELECTED_CORE_PACKAGES[@]}"
            gum style --foreground "$COLOR_FG" "  Extra pkgs: ${#SELECTED_ADDITIONAL_PACKAGES[@]}"
            gum style --foreground "$COLOR_FG" "  Path swap:  $([ "$PATH_REPLACEMENT_SKIPPED" == false ] && echo yes || echo skipped)"
            echo
            if gum_confirm "Proceed with install?"; then
                ((STEP++))
            else
                ((STEP--))
            fi
            ;;
        esac
    done

    ALL_SELECTED_PACKAGES=("${SELECTED_CORE_PACKAGES[@]}" "${SELECTED_ADDITIONAL_PACKAGES[@]}")
}

# ── Tier: Opinionated ─────────────────────────────────────────────────────────
phase_opinionated() {
    TERMINAL_CHOICE="ghostty"
    mapfile -t SELECTED_CORE_PACKAGES < <(
        grep -v '^\[font\]' "$DOTFILES_DIR/packages/core.txt" | awk '{print $NF}'
    )
    SELECTED_ADDITIONAL_PACKAGES=()
    PATH_REPLACEMENT_SKIPPED=false
    ALL_SELECTED_PACKAGES=("${SELECTED_CORE_PACKAGES[@]}")
    export TERMINAL_CHOICE PATH_REPLACEMENT_SKIPPED ALL_SELECTED_PACKAGES
}

# ── Tier: Minimal ─────────────────────────────────────────────────────────────
phase_minimal() {
    TERMINAL_CHOICE="kitty"
    mapfile -t SELECTED_CORE_PACKAGES < <(
        grep -E '^\[(hypr|ui)\]' "$DOTFILES_DIR/packages/core.txt" | awk '{print $NF}'
    )
    SELECTED_ADDITIONAL_PACKAGES=()
    PATH_REPLACEMENT_SKIPPED=false
    ALL_SELECTED_PACKAGES=("${SELECTED_CORE_PACKAGES[@]}")
    export TERMINAL_CHOICE PATH_REPLACEMENT_SKIPPED ALL_SELECTED_PACKAGES
}

# ── Phase 3 — Execution ───────────────────────────────────────────────────────
phase_execute() {
    if [[ "$INSTALL_TIER" == "dryrun" ]]; then
        clear
        print_banner
        echo
        gum style --foreground "$COLOR_ACCENT" --bold "  DRY RUN — no changes will be made"
        echo
        print_header "Would install (must-install):"
        while IFS= read -r pkg; do
            print_info "$pkg"
        done < "$DOTFILES_DIR/packages/must-install.txt"
        echo
        print_header "Would install (selected):"
        printf '%s\n' "${ALL_SELECTED_PACKAGES[@]}" | while IFS= read -r pkg; do
            print_info "$pkg"
        done
        echo
        print_header "Would stow:"
        resolve_stow_dirs "${ALL_SELECTED_PACKAGES[@]}"
        printf '%s\n' "${STOW_DIRS[@]}" | while IFS= read -r d; do
            print_info "$d"
        done
        echo
        print_header "Would replace paths in configs for user: $USER"
        replace_paths true
        echo
        gum style --foreground "$COLOR_DIM" "  Log file: $LOG_FILE"
        return
    fi

    clear
    print_banner
    echo

    # 3a. System update
    gum_spin --title "Updating system..." -- \
        paru -Syu --noconfirm >> "$LOG_FILE" 2>&1
    log_info "System updated"

    # 3b. Packages
    print_header "Installing packages..."
    check_steam_multilib
    install_packages "${ALL_SELECTED_PACKAGES[@]}"

    # 3c. Terminal
    stow_terminal "$TERMINAL_CHOICE"

    # 3d/3e. Stow
    gum_spin --title "Deploying configs..." -- sleep 0.5
    run_full_stow "$TERMINAL_CHOICE" "${ALL_SELECTED_PACKAGES[@]}"

    # 3f. Font cache
    gum_spin --title "Rebuilding font cache..." -- fc-cache -fv >> "$LOG_FILE" 2>&1
    log_info "Font cache rebuilt"

    # 3g. Wallpaper bootstrap
    if [[ ! -d "$HOME/photos/wallpapers" ]]; then
        mkdir -p "$HOME/photos/wallpapers"
        cp "$DOTFILES_DIR/wallpapers/"* "$HOME/photos/wallpapers/" 2>/dev/null || true
        log_info "Wallpapers seeded to ~/photos/wallpapers/"
    fi

    # 3h. Path replacement
    bootstrap_example_configs
    if [[ "$PATH_REPLACEMENT_SKIPPED" != true ]]; then
        gum_spin --title "Replacing hardcoded paths..." -- \
            bash -c "
                DOTFILES_DIR='$DOTFILES_DIR'
                USER='$USER'
                source '$DOTFILES_DIR/lib/helpers.sh'
                source '$DOTFILES_DIR/modules/paths.sh'
                replace_paths false
            "
    fi

    # 3i. Services
    gum_spin --title "Enabling services..." -- bash -c "
        source '$DOTFILES_DIR/lib/helpers.sh'
        source '$DOTFILES_DIR/modules/services.sh'
        run_services
    "

    # 3j. Shell
    run_shell

    # Run matugen with default wallpaper
    local default_wall="$HOME/photos/wallpapers/1-osaka-jade-bg.jpg"
    if [[ -f "$default_wall" ]] && command_exists matugen; then
        gum_spin --title "Generating color theme..." -- \
            matugen image "$default_wall" --mode dark -t scheme-tonal-spot >> "$LOG_FILE" 2>&1
        log_info "Matugen ran with default wallpaper"
    else
        log_warn "Matugen skipped — wallpaper or matugen not found"
    fi
}

# ── Phase 4 — Summary ─────────────────────────────────────────────────────────
phase_summary() {
    [[ "$INSTALL_TIER" == "dryrun" ]] && return

    clear
    print_banner
    echo
    print_header "Install complete"
    echo

    # Package results
    for entry in "${PKG_RESULTS[@]:-}"; do
        local pkg="${entry%%:*}"
        local result="${entry##*:}"
        case "$result" in
            installed)          gum style --foreground "$COLOR_ACCENT" "  ✓  $pkg" ;;
            already_installed)  gum style --foreground "$COLOR_DIM"    "  ✓  $pkg (already present)" ;;
            failed)             gum style --foreground "#ff6666"        "  ✗  $pkg (failed — see log)" ;;
        esac
    done

    echo

    # Backed up files
    if [[ ${#BACKED_UP_FILES[@]} -gt 0 ]]; then
        print_header "Backed up files (renamed before stow):"
        for f in "${BACKED_UP_FILES[@]}"; do
            print_info "$f"
        done
        echo
    fi

    # Follow-up items
    if [[ "${PATH_REPLACEMENT_SKIPPED:-false}" == true ]]; then
        gum style --foreground "$COLOR_ACCENT" "  ⚠  Path replacement skipped — run manually:"
        print_info "sed -i 's|/home/yourusername/|/home/\$USER/|g' ~/.config/hypr/hyprpaper.conf"
        print_info "sed -i 's|/home/yourusername/|/home/\$USER/|g' ~/.config/hypr/hyprlock.conf"
        print_info "sed -i 's|/home/yourusername/|/home/\$USER/|g' ~/.config/rofi/launcher.rasi"
        echo
    fi

    if [[ "${SHELL_CHANGED:-false}" == true ]]; then
        gum style --foreground "$COLOR_ACCENT" "  ⚠  Shell changed to fish — log out to apply."
        echo
    fi

    if systemctl is-enabled sddm &>/dev/null && ! systemctl is-active sddm &>/dev/null; then
        gum style --foreground "$COLOR_ACCENT" "  ⚠  SDDM enabled — reboot to start the display manager."
        echo
    fi

    gum style --foreground "$COLOR_DIM" "  Log: $LOG_FILE"
    echo
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    # Phase 0 — Bootstrap (silent until gum is ready)
    run_bootstrap

    # Phase 1 — Welcome + tier selection
    phase_welcome

    # Phase 2 — Build selections based on tier
    case "$INSTALL_TIER" in
        custom)      phase_custom ;;
        opinionated) phase_opinionated ;;
        minimal)     phase_minimal ;;
        dryrun)      phase_opinionated ;;  # use opinionated selections for preview
    esac

    # Phase 3 — Execute
    phase_execute

    # Phase 4 — Summary
    phase_summary
}

main "$@"
