#!/usr/bin/env bash
# Phase 3i — Systemd service enablement (idempotent)

source "$(dirname "${BASH_SOURCE[0]}")/../lib/helpers.sh"

enable_service() {
    local service="$1"
    local scope="${2:-system}"  # "system" or "user"

    if [[ "$scope" == "user" ]]; then
        if systemctl --user is-enabled "$service" &>/dev/null; then
            log_info "Service already enabled (user): $service"
            return 0
        fi
        if systemctl --user enable "$service" >> "$LOG_FILE" 2>&1; then
            log_success "Enabled (user): $service"
        else
            log_error "Failed to enable (user): $service"
        fi
    else
        if systemctl is-enabled "$service" &>/dev/null; then
            log_info "Service already enabled: $service"
            return 0
        fi
        if sudo systemctl enable "$service" >> "$LOG_FILE" 2>&1; then
            log_success "Enabled: $service"
        else
            log_error "Failed to enable: $service"
        fi
    fi
}

run_services() {
    local installed_packages=("$@")

    # User services (no sudo)
    enable_service pipewire    user
    enable_service wireplumber user

    # System services
    enable_service NetworkManager

    # Conditional on package being installed
    if is_installed bluez; then
        enable_service bluetooth
    fi

    if is_installed docker; then
        enable_service docker
    fi

    log_info "Service setup complete"
}
