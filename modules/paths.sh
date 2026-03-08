#!/usr/bin/env bash
# Phase 3h — Path replacement and gitignored config bootstrapping

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/gum-styles.sh"

PLACEHOLDER="yourusername"

# Gitignored configs: source (.example in repo) → destination (live path)
declare -A EXAMPLE_CONFIGS=(
    ["$DOTFILES_DIR/hypr/.config/hypr/hyprpaper.conf.example"]="$HOME/.config/hypr/hyprpaper.conf"
    ["$DOTFILES_DIR/hypr/.config/hypr/hyprlock.conf.example"]="$HOME/.config/hypr/hyprlock.conf"
    ["$DOTFILES_DIR/rofi/.config/rofi/launcher.rasi.example"]="$HOME/.config/rofi/launcher.rasi"
    ["$DOTFILES_DIR/wlogout/.config/wlogout/style.css.example"]="$HOME/.config/wlogout/style.css"
)

# ── Bootstrap gitignored configs from .example files ─────────────────────────
bootstrap_example_configs() {
    for src in "${!EXAMPLE_CONFIGS[@]}"; do
        local dest="${EXAMPLE_CONFIGS[$src]}"

        if [[ ! -f "$src" ]]; then
            log_warn "Example not found: $src — skipping"
            continue
        fi

        if [[ -f "$dest" ]]; then
            log_info "Config already exists: $dest — skipping"
            continue
        fi

        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        log_info "Bootstrapped: $dest from $src"
    done
}

# ── Replace hardcoded paths ───────────────────────────────────────────────────
# Replaces /home/yourusername/ and /home/<any_user>/ with /home/$USER/
replace_paths() {
    local dry_run="${1:-false}"

    # Collect all stowed config files + bootstrapped gitignored configs
    local target_files=()

    # Bootstrapped gitignored configs
    for dest in "${EXAMPLE_CONFIGS[@]}"; do
        [[ -f "$dest" ]] && target_files+=("$dest")
    done

    # Stowed symlink targets (resolve to real file in dotfiles)
    while IFS= read -r -d '' file; do
        if [[ -L "$file" ]]; then
            local real
            real="$(readlink -f "$file")"
            [[ "$real" == "$DOTFILES_DIR"* ]] && target_files+=("$real")
        fi
    done < <(find "$HOME/.config" -maxdepth 4 -print0 2>/dev/null)

    # Dedup
    mapfile -t target_files < <(printf '%s\n' "${target_files[@]}" | sort -u)

    if [[ "$dry_run" == true ]]; then
        print_header "Path replacement preview"
        echo
        local found=false
        for f in "${target_files[@]}"; do
            if grep -qE "/home/[^/]+" "$f" 2>/dev/null; then
                gum style --foreground "$COLOR_DIM" "  $f"
                grep -nE "/home/[^/]+" "$f" | while IFS= read -r line; do
                    gum style --foreground "$COLOR_SURFACE" "    $line"
                done
                found=true
            fi
        done
        [[ "$found" == false ]] && print_info "No hardcoded paths found."
        echo
        return 0
    fi

    local count=0
    for f in "${target_files[@]}"; do
        if grep -qE "/home/[^/]+" "$f" 2>/dev/null; then
            sed -i "s|/home/$PLACEHOLDER/|/home/$USER/|g" "$f"
            sed -i "s|/home/[^/]*/|/home/$USER/|g" "$f"
            log_info "Path replaced in: $f"
            ((count++))
        fi
    done

    log_info "Path replacement complete — $count files updated"
}

# ── Entry point ───────────────────────────────────────────────────────────────
run_paths() {
    local skip="${1:-false}"

    bootstrap_example_configs

    if [[ "$skip" == true ]]; then
        log_info "Path replacement skipped by user"
        PATH_REPLACEMENT_SKIPPED=true
        export PATH_REPLACEMENT_SKIPPED
        return
    fi

    print_step "" "" "Path Replacement"
    echo
    print_info "The following files contain hardcoded home paths that will be updated to /home/$USER/"
    echo

    replace_paths true  # dry run preview

    if gum_confirm "Apply path replacement?"; then
        gum_spin --title "Replacing paths..." -- bash -c "
            source '$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh'
            source '$(dirname "${BASH_SOURCE[0]}")/../modules/paths.sh'
            replace_paths false
        "
        PATH_REPLACEMENT_SKIPPED=false
    else
        log_info "Path replacement declined by user"
        PATH_REPLACEMENT_SKIPPED=true
    fi

    export PATH_REPLACEMENT_SKIPPED
}
