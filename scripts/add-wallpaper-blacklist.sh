#!/usr/bin/env bash
# Agrega el wallpaper activo a la blacklist y solicita un cambio.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-engine"
CURRENT_WALLPAPER_FILE="$RUNTIME_DIR/current-wallpaper"
BLACKLIST_FILE="$SCRIPT_DIR/wallpaper-blacklist.txt"
WALLPAPER_SCRIPT="$SCRIPT_DIR/wallpaper-random.sh"

ENGINE_PATTERN='[l]inux-wallpaperengine'

get_current_id() {
    local path=""

    if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
        path=$(<"$CURRENT_WALLPAPER_FILE")
        if [[ -n "$path" ]]; then
            basename "$path"
            return 0
        fi
    fi

    pgrep -af "$ENGINE_PATTERN" 2>/dev/null \
        | grep -o 'content/431960/[0-9]*' \
        | grep -o '[0-9]*$' \
        | head -n1
}

ID=$(get_current_id || true)

if [[ -z "$ID" ]]; then
    notify-send "Wallpaper Engine" "No hay wallpaper activo"
    exit 1
fi

touch "$BLACKLIST_FILE"

if grep -qxF "$ID" "$BLACKLIST_FILE"; then
    notify-send "Wallpaper Engine" "$ID ya está en la blacklist"
else
    echo "$ID" >>"$BLACKLIST_FILE"
    notify-send "Wallpaper Engine" "Añadido $ID a la blacklist"
fi

exec "$WALLPAPER_SCRIPT"
