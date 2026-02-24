#!/usr/bin/env bash
# ~/.config/rofi/launcher.sh

TERMINAL="ghostty"
ROFI_THEME="$HOME/.config/rofi/launcher.rasi"

#MSG="Alt+1: 󰇥 Yazi    Alt+2: 󰂯 Bluetui    Alt+3: 󰖟 Brave"
MSG="Alt+1: Yazi    Alt+2: Bluetui    Alt+3: Brave"
rofi \
    -show drun \
    -theme "$ROFI_THEME" \
    -theme-str 'window { location: north; anchor: north; y-offset: 20px; }' \
    -drun-display-format "{name}" \
    -show-icons \
    -mesg "$MSG" \
    -kb-custom-1 "alt+1" \
    -kb-custom-2 "alt+2" \
    -kb-custom-3 "alt+3"

EXIT_CODE=$?

case $EXIT_CODE in
    10)
        $TERMINAL --title=yazi -e yazi &
        ;;
    11)
        $TERMINAL --title=bluetui -e bluetui &
        ;;
    12)
        brave &
        ;;
esac
