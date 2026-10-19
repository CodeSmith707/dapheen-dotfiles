
#!/usr/bin/env bash
set -uo pipefail

CONFIG="$1/config.json"

expand_home() {
    local path="$1"
    if [[ "$path" == '$HOME' ]]; then
        printf '%s\n' "$HOME"
    elif [[ "$path" == '$HOME/'* ]]; then
        printf '%s/%s\n' "$HOME" "${path#'$HOME/'}"
    else
        printf '%s\n' "$path"
    fi
}

wallpaper_path=$(expand_home "$(jq -r '.wallpaper_path' "$CONFIG")")
cache_path=$(expand_home "$(jq -r '.cache_path' "$CONFIG")")
cache_batch_size=$(jq -r '.cache_batch_size // 4' "$CONFIG")

mkdir -p "$cache_path"

find "$wallpaper_path" -maxdepth 1 -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" \
\) -print0 |
while IFS= read -r -d '' img; do
    filename=$(basename "$img")
    out="$cache_path/$filename"

    # Skip only a valid, non-empty cached image.
    if [[ -s "$out" ]] && identify "$out" >/dev/null 2>&1; then
        continue
    fi

    tmp=$(mktemp "$cache_path/.thumb.XXXXXX") || continue

    if convert "$img" -thumbnail x500 -strip -quality 85 "$tmp" \
        && identify "$tmp" >/dev/null 2>&1; then
        mv -f -- "$tmp" "$out"
    else
        rm -f -- "$tmp"
        printf 'Failed to cache: %s\n' "$img" >&2
    fi
done

printf 'Thumbnail generation complete.\n'
