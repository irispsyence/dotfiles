#!/usr/bin/env bash
# Phase 3j — Shell configuration

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

run_shell() {
    local fish_path
    fish_path="$(which fish 2>/dev/null)"

    if [[ -z "$fish_path" ]]; then
        log_warn "fish not found — skipping shell change"
        SHELL_CHANGED=false
        export SHELL_CHANGED
        return
    fi

    if [[ "$SHELL" == "$fish_path" ]]; then
        log_info "Shell already set to fish — skipping"
        SHELL_CHANGED=false
        export SHELL_CHANGED
        return
    fi

    # Add fish to /etc/shells if not present
    if ! grep -q "$fish_path" /etc/shells; then
        echo "$fish_path" | sudo tee -a /etc/shells >> "$LOG_FILE" 2>&1
        log_info "Added $fish_path to /etc/shells"
    fi

    if chsh -s "$fish_path"; then
        log_success "Default shell changed to fish"
        SHELL_CHANGED=true
    else
        log_error "Failed to change shell to fish"
        SHELL_CHANGED=false
    fi

    export SHELL_CHANGED
}
