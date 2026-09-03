#!/usr/bin/env bash
# Daemon singleton: temporizador + detección fullscreen/juegos + solicitud de cambio.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-engine"
AUTO_LOCK="$RUNTIME_DIR/auto.lock"
WALLPAPER_SCRIPT="$SCRIPT_DIR/wallpaper-random.sh"
LOG_FILE="$RUNTIME_DIR/wallpaper.log"

INTERVAL=60

mkdir -p "$RUNTIME_DIR"

exec 9>"$AUTO_LOCK"
if ! flock -n 9; then
    exit 0
fi

echo $$ >"$RUNTIME_DIR/auto.pid"

log() {
    echo "[$(date '+%F %T')] $*" >>"$LOG_FILE"
}

cleanup() {
    log "wallpaper-auto terminado (pid $$)"
    rm -f "$RUNTIME_DIR/auto.pid"
}
trap cleanup EXIT

log "wallpaper-auto iniciado (pid $$, interval=${INTERVAL}s)"

# Solo omitir si hay fullscreen real o un cliente claramente de juego.
should_skip_change() {
    local clients
    clients=$(hyprctl clients -j 2>/dev/null) || return 1
    [[ "$clients" == \[* ]] || return 1

    jq -e '
        any(.[];
            (.mapped // false) and
            ((.hidden // false) | not) and
            (
                ((.fullscreen // 0) | tonumber? // 0) != 0 or
                ((.fullscreenClient // 0) | tonumber? // 0) != 0 or
                (.content == "game") or
                ((.class // "") | test("^steam_app_")) or
                ((.class // "") == "gamescope") or
                ((.initialClass // "") | test("^steam_app_")) or
                ((.initialClass // "") == "gamescope")
            )
        )
    ' >/dev/null <<<"$clients"
}

request_wallpaper_change() {
    log "Cambiando wallpaper..."
    if "$WALLPAPER_SCRIPT" >>"$LOG_FILE" 2>&1; then
        log "Cambio OK"
    else
        log "Fallo al cambiar wallpaper (exit $?)"
    fi
}

if should_skip_change; then
    log "Fullscreen/juego al arranque, se omite el cambio inicial"
else
    request_wallpaper_change
fi

while true; do
    sleep "$INTERVAL"
    if should_skip_change; then
        log "Fullscreen/juego detectado, omitiendo cambio"
    else
        request_wallpaper_change
    fi
done
