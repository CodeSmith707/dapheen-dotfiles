#!/usr/bin/env bash
# Replace "random" with: fade, wipe, grow, outer, wave, center, any, random

img="$1"
[[ -f "$img" ]] || { echo "commands.sh: not a file: $img" >&2; exit 1; }

awww img "$img" -t random --transition-duration 1

mkdir -p "$HOME/.cache/dapheen"

setsid -f bash -c '
    python3 "$HOME/.config/dapheen/bin/theme.py" wallpaper "$1" \
        >>"$HOME/.cache/dapheen/theme.log" 2>&1 || exit 1

    python3 "$HOME/.config/dapheen/bin/spicetify-sync.py" \
        >>"$HOME/.cache/dapheen/theme.log" 2>&1
' _ "$img" </dev/null >/dev/null 2>&1
