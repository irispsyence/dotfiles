#!/bin/bash
# ~/.config/matugen/reload.sh
# Called after matugen generates all templates

export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/1000}

# Reload hyprland colors
hyprctl reload 2>/dev/null || true

# Reload swaync
swaync-client --reload-config
sleep 0.2
swaync-client -rs

# Reload tmux only if a session exists
if tmux list-sessions &>/dev/null; then
    tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
fi

# Restart waybar
pkill waybar
waybar &

# Restart ags calendar if config exists
if [ -d ~/.config/ags ]; then
    ags quit 2>/dev/null || true
    ags run -d ~/.config/ags &
fi

