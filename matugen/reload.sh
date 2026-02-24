#!/bin/bash
# ~/.config/matugen/reload.sh
# Called after matugen generates all templates

# Reload hyprland colors
hyprctl reload 2>/dev/null || true

# Restart waybar
pkill waybar
waybar &

# Reload swaync
swaync-client --reload-config
sleep 0.2
swaync-client -rs

# Reload tmux only if a session exists
if tmux list-sessions &>/dev/null; then
    tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || true
fi
