#!/usr/bin/env bash
# Centralized gum styling — never inline gum styles in modules

# Palette (matches matugen/hyprtoolkit.conf theme)
COLOR_BG="#0f1512"
COLOR_FG="#dee4df"
COLOR_ACCENT="#88d6ba"
COLOR_SURFACE="#3f4944"
COLOR_DIM="#b2ccc1"
BORDER_STYLE="double"

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
    gum style \
        --border "$BORDER_STYLE" \
        --border-foreground "$COLOR_ACCENT" \
        --foreground "$COLOR_ACCENT" \
        --background "$COLOR_BG" \
        --bold \
        --padding "1 4" \
        --align center \
        "Hyprland dotfiles"
}

# ── Step indicator ────────────────────────────────────────────────────────────
print_step() {
    local current="$1"
    local total="$2"
    local label="$3"
    gum style \
        --border "$BORDER_STYLE" \
        --border-foreground "$COLOR_SURFACE" \
        --foreground "$COLOR_ACCENT" \
        --padding "0 2" \
        "Step ${current} of ${total} — ${label}"
}

# ── Section header (no border, just styled text) ──────────────────────────────
print_header() {
    gum style \
        --foreground "$COLOR_ACCENT" \
        --bold \
        "  $1"
}

# ── Info line ─────────────────────────────────────────────────────────────────
print_info() {
    gum style --foreground "$COLOR_DIM" "  $1"
}

# ── Confirm wrapper ───────────────────────────────────────────────────────────
gum_confirm() {
    gum confirm \
        --prompt.foreground "$COLOR_ACCENT" \
        --selected.background "$COLOR_SURFACE" \
        --selected.foreground "$COLOR_ACCENT" \
        --unselected.foreground "$COLOR_DIM" \
        "$@"
}

# ── Single-select wrapper ─────────────────────────────────────────────────────
gum_choose() {
    gum choose \
        --cursor.foreground "$COLOR_ACCENT" \
        --selected.foreground "$COLOR_ACCENT" \
        --selected.background "$COLOR_SURFACE" \
        --item.foreground "$COLOR_FG" \
        "$@"
}

# ── Multi-select wrapper ──────────────────────────────────────────────────────
gum_multiselect() {
    gum choose --no-limit \
        --cursor.foreground "$COLOR_ACCENT" \
        --selected.foreground "$COLOR_BG" \
        --selected.background "$COLOR_ACCENT" \
        --item.foreground "$COLOR_FG" \
        "$@"
}

# ── Spinner wrapper ───────────────────────────────────────────────────────────
gum_spin() {
    gum spin \
        --spinner dot \
        --spinner.foreground "$COLOR_ACCENT" \
        --title.foreground "$COLOR_FG" \
        "$@"
}
