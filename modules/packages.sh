#!/usr/bin/env bash
# Phase 3b — Package installation
# Expects: SELECTED_PACKAGES array populated by install.sh

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gum-styles.sh"

# ── Build package selections for Custom flow ──────────────────────────────────
select_core_packages() {
    local core_file="$DOTFILES_DIR/packages/core.txt"

    print_header "Hyprland Ecosystem"
    print_info "Fonts are pre-installed. Deselect anything you don't want."
    echo

    local hypr_pkgs ui_pkgs shell_pkgs tool_pkgs
    mapfile -t hypr_pkgs  < <(get_packages_by_tag "$core_file" "hypr")
    mapfile -t ui_pkgs    < <(get_packages_by_tag "$core_file" "ui")
    mapfile -t shell_pkgs < <(get_packages_by_tag "$core_file" "shell")
    mapfile -t tool_pkgs  < <(get_packages_by_tag "$core_file" "tools")

    print_step "$1" "6" "Main Packages"
    echo

    gum style --foreground "$COLOR_DIM" "  [ Hyprland ecosystem ] — all pre-checked"
    local selected_hypr
    mapfile -t selected_hypr < <(printf '%s\n' "${hypr_pkgs[@]}" | gum_multiselect --selected "$(IFS=,; echo "${hypr_pkgs[*]}")")

    echo
    gum style --foreground "$COLOR_DIM" "  [ Core UI ] — all pre-checked"
    local selected_ui
    mapfile -t selected_ui < <(printf '%s\n' "${ui_pkgs[@]}" | gum_multiselect --selected "$(IFS=,; echo "${ui_pkgs[*]}")")

    echo
    gum style --foreground "$COLOR_DIM" "  [ Shell + Tools ] — all pre-checked"
    local selected_tools
    mapfile -t selected_tools < <(printf '%s\n' "${shell_pkgs[@]}" "${tool_pkgs[@]}" | gum_multiselect --selected "$(IFS=,; echo "${shell_pkgs[*]},${tool_pkgs[*]}")")

    SELECTED_CORE_PACKAGES=("${selected_hypr[@]}" "${selected_ui[@]}" "${selected_tools[@]}")
    export SELECTED_CORE_PACKAGES
}

select_additional_packages() {
    local add_file="$DOTFILES_DIR/packages/additional.txt"

    print_step "$1" "6" "Additional Packages"
    print_info "None pre-checked — select anything you want to install."
    echo

    mapfile -t all_tags < <(get_all_tags "$add_file")

    SELECTED_ADDITIONAL_PACKAGES=()

    for tag in "${all_tags[@]}"; do
        mapfile -t tag_pkgs < <(get_packages_by_tag "$add_file" "$tag")
        gum style --foreground "$COLOR_DIM" "  [ $tag ]"
        local selected
        mapfile -t selected < <(printf '%s\n' "${tag_pkgs[@]}" | gum_multiselect)
        SELECTED_ADDITIONAL_PACKAGES+=("${selected[@]}")
        echo
    done

    export SELECTED_ADDITIONAL_PACKAGES
}

# ── Install selected packages ─────────────────────────────────────────────────
install_packages() {
    local packages=("$@")
    local -g PKG_RESULTS=()

    # Pacman pass first, then AUR
    local pacman_pkgs=() aur_pkgs=()
    for pkg in "${packages[@]}"; do
        if is_aur "$pkg"; then
            aur_pkgs+=("$pkg")
        else
            pacman_pkgs+=("$pkg")
        fi
    done

    for pkg in "${pacman_pkgs[@]}"; do
        pkg_install "$pkg"
        PKG_RESULTS+=("$pkg:$PKG_LAST_RESULT")
    done

    for pkg in "${aur_pkgs[@]}"; do
        pkg_install "$pkg"
        PKG_RESULTS+=("$pkg:$PKG_LAST_RESULT")
    done

    export PKG_RESULTS
}

# ── Steam multilib check ──────────────────────────────────────────────────────
check_steam_multilib() {
    if [[ " ${SELECTED_ADDITIONAL_PACKAGES[*]} " == *" steam "* ]]; then
        if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
            echo
            gum style --foreground "$COLOR_ACCENT" "  Steam requires [multilib] to be enabled in /etc/pacman.conf."
            if gum_confirm "Enable multilib now?"; then
                sudo sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/\[multilib\]\nInclude/}' /etc/pacman.conf
                sudo pacman -Sy >> "$LOG_FILE" 2>&1
                log_info "multilib enabled"
            else
                log_warn "multilib not enabled — steam install may fail"
            fi
        fi
    fi
}
