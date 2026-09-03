#!/usr/bin/env bash
# Selecciona un wallpaper e inicia linux-wallpaperengine.
#
# Recorre TODA la colección válida (menos blacklist) antes de repetir.
# La baraja persiste en disco: sobrevive reinicios hasta completar el ciclo.
#
# Handoff (misma layer background):
#  1) Anotar PIDs viejos
#  2) Lanzar el NUEVO (el viejo sigue animando)
#  3) Esperar a que el NUEVO tenga layer en Hyprland
#  4) Matar los viejos
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-engine"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-engine"
CHANGE_LOCK="$RUNTIME_DIR/change.lock"
ENGINE_PID_FILE="$RUNTIME_DIR/engine.pid"
CURRENT_WALLPAPER_FILE="$RUNTIME_DIR/current-wallpaper"
BLACKLIST_FILE="$SCRIPT_DIR/wallpaper-blacklist.txt"
QUEUE_FILE="$STATE_DIR/queue.ids"
SEEN_FILE="$STATE_DIR/seen.ids"
LEGACY_PLAYED="$RUNTIME_DIR/played.ids"

ASSETS="/mnt/Almighty/Program Files (x86)/Steam/steamapps/common/wallpaper_engine/assets"
WORKSHOP="/mnt/Almighty/Program Files (x86)/Steam/steamapps/workshop/content/431960"
MONITOR="HDMI-A-1"

CHANGE_TIMEOUT=30
READY_TIMEOUT=25
SETTLE_SECONDS=1
MAX_LOAD_ATTEMPTS=8

mkdir -p "$RUNTIME_DIR" "$STATE_DIR"
touch "$BLACKLIST_FILE"

declare -A BLACKLIST_SET=()
declare -A POOL_SET=()
declare -A POOL_TYPE=()
declare -A POOL_TITLE=()
declare -a POOL_IDS=()
POOL_LOADED=0

load_blacklist() {
    local id
    BLACKLIST_SET=()
    [[ -f "$BLACKLIST_FILE" ]] || return 0
    while IFS= read -r id; do
        [[ -n "$id" && "$id" != \#* ]] || continue
        BLACKLIST_SET["$id"]=1
    done < <(grep -vE '^\s*(#|$)' "$BLACKLIST_FILE" || true)
}

atomic_write() {
    local file="$1" tmp
    tmp="${file}.tmp.$$"
    cat >"$tmp"
    mv -f "$tmp" "$file"
}

write_ids() {
    local file="$1"
    shift
    if (($# > 0)); then
        printf '%s\n' "$@" | atomic_write "$file"
    else
        : | atomic_write "$file"
    fi
}

read_ids() {
    local file="$1" id
    [[ -f "$file" ]] || return 0
    while IFS= read -r id; do
        [[ -n "$id" && "$id" != \#* ]] || continue
        printf '%s\n' "$id"
    done <"$file"
}

migrate_legacy_seen() {
    if [[ -s "$SEEN_FILE" ]]; then
        return 0
    fi
    if [[ -s "$LEGACY_PLAYED" ]]; then
        cp -f "$LEGACY_PLAYED" "$SEEN_FILE"
        echo "Migrados $(grep -c . "$SEEN_FILE" || true) IDs de la sesión actual a la baraja persistente" >&2
    fi
}

load_pool() {
    local row id wtype title
    POOL_SET=()
    POOL_TYPE=()
    POOL_TITLE=()
    POOL_IDS=()
    load_blacklist

    while IFS=$'\t' read -r id wtype title; do
        [[ -n "$id" ]] || continue
        [[ -n "${BLACKLIST_SET[$id]:-}" ]] && continue
        POOL_SET["$id"]=1
        POOL_TYPE["$id"]="$wtype"
        POOL_TITLE["$id"]="$title"
        POOL_IDS+=("$id")
    done < <(
        python3 - "$WORKSHOP" <<'PY'
import json, sys
from pathlib import Path

workshop = Path(sys.argv[1])
video_ext = {".mp4", ".webm", ".mkv", ".avi", ".mov"}

for d in sorted(workshop.iterdir(), key=lambda p: p.name):
    if not d.is_dir():
        continue
    project = d / "project.json"
    if not project.is_file():
        continue
    try:
        data = json.loads(project.read_text(encoding="utf-8", errors="replace"))
    except json.JSONDecodeError:
        continue
    wtype = str(data.get("type") or "").strip().lower()
    file = str(data.get("file") or "")
    title = str(data.get("title") or "").replace("\t", " ").replace("\n", " ")
    ok = False
    if wtype == "scene":
        ok = any((d / name).is_file() for name in (
            "scene.pkg", "scene.json", "gifscene.pkg", "gifscene.json"
        )) or bool(file and (d / file).is_file())
    elif wtype == "video":
        ok = bool(file and (d / file).is_file()) or any(
            x.is_file() and x.suffix.lower() in video_ext for x in d.iterdir()
        )
    elif wtype == "web":
        ok = (d / "index.html").is_file() or bool(file and (d / file).is_file())
    if ok:
        print(f"{d.name}\t{wtype}\t{title}")
PY
    )

    POOL_LOADED=1
    if ((${#POOL_IDS[@]} == 0)); then
        echo "ERROR: No hay wallpapers válidos (revisa workshop/blacklist)" >&2
        return 1
    fi
}

ensure_pool() {
    ((POOL_LOADED == 1)) || load_pool
}

shuffle_ids() {
    if (($# == 0)); then
        return 0
    fi
    printf '%s\n' "$@" | shuf
}

current_wallpaper_id() {
    local path=""
    if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
        path=$(<"$CURRENT_WALLPAPER_FILE")
        [[ -n "$path" ]] && basename "$path"
    fi
}

# Baraja persistente: queue.ids = pendientes, seen.ids = ya salieron en este ciclo.
# Solo se reconstruye cuando se recorrió toda la colección válida.
sync_queue() {
    local id current_id
    local -a seen_keep=() queue_keep=() fresh=() rebuilt=()
    local -A seen_set=() queue_set=()

    ensure_pool
    migrate_legacy_seen
    current_id=$(current_wallpaper_id || true)

    while IFS= read -r id; do
        [[ -n "${POOL_SET[$id]:-}" ]] || continue
        [[ -n "${seen_set[$id]:-}" ]] && continue
        seen_set["$id"]=1
        seen_keep+=("$id")
    done < <(read_ids "$SEEN_FILE")

    if [[ -n "$current_id" && -n "${POOL_SET[$current_id]:-}" && -z "${seen_set[$current_id]:-}" ]]; then
        seen_set["$current_id"]=1
        seen_keep+=("$current_id")
    fi

    while IFS= read -r id; do
        [[ -n "${POOL_SET[$id]:-}" ]] || continue
        [[ -n "${seen_set[$id]:-}" ]] && continue
        [[ -n "${queue_set[$id]:-}" ]] && continue
        queue_set["$id"]=1
        queue_keep+=("$id")
    done < <(read_ids "$QUEUE_FILE")

    for id in "${POOL_IDS[@]}"; do
        [[ -n "${seen_set[$id]:-}" ]] && continue
        [[ -n "${queue_set[$id]:-}" ]] && continue
        fresh+=("$id")
    done

    if ((${#fresh[@]} > 0)); then
        while IFS= read -r id; do
            [[ -n "$id" ]] || continue
            queue_keep+=("$id")
            queue_set["$id"]=1
        done < <(shuffle_ids "${fresh[@]}")
    fi

    if ((${#queue_keep[@]} == 0)); then
        echo "Ciclo completo: barajando ${#POOL_IDS[@]} wallpapers válidos (blacklist=${#BLACKLIST_SET[@]})" >&2
        seen_keep=()
        seen_set=()
        if [[ -n "$current_id" && -n "${POOL_SET[$current_id]:-}" ]]; then
            seen_keep+=("$current_id")
            seen_set["$current_id"]=1
        fi
        for id in "${POOL_IDS[@]}"; do
            [[ -n "${seen_set[$id]:-}" ]] && continue
            rebuilt+=("$id")
        done
        queue_keep=()
        if ((${#rebuilt[@]} > 0)); then
            while IFS= read -r id; do
                [[ -n "$id" ]] || continue
                queue_keep+=("$id")
            done < <(shuffle_ids "${rebuilt[@]}")
        elif [[ -n "$current_id" ]]; then
            queue_keep+=("$current_id")
            seen_keep=()
        fi
    fi

    write_ids "$SEEN_FILE" "${seen_keep[@]+"${seen_keep[@]}"}"
    write_ids "$QUEUE_FILE" "${queue_keep[@]+"${queue_keep[@]}"}"
}

mark_seen() {
    local id="$1"
    [[ -n "$id" ]] || return 0
    if [[ -f "$SEEN_FILE" ]] && grep -qxF "$id" "$SEEN_FILE"; then
        return 0
    fi
    echo "$id" >>"$SEEN_FILE"
}

pop_queue_id() {
    local id rest
    local -a queue=()

    sync_queue
    mapfile -t queue < <(read_ids "$QUEUE_FILE")
    if ((${#queue[@]} == 0)); then
        echo "ERROR: La cola de wallpapers quedó vacía" >&2
        return 1
    fi

    id="${queue[0]}"
    if ((${#queue[@]} > 1)); then
        write_ids "$QUEUE_FILE" "${queue[@]:1}"
    else
        write_ids "$QUEUE_FILE"
    fi
    mark_seen "$id"
    printf '%s\n' "$id"
}

wallpaper_path() {
    printf '%s/%s\n' "$WORKSHOP" "$1"
}

pick_wallpaper() {
    local id remaining seen_count
    id=$(pop_queue_id)
    remaining=$(read_ids "$QUEUE_FILE" | grep -c . || true)
    seen_count=$(read_ids "$SEEN_FILE" | grep -c . || true)
    echo "Selección: id=$id type=${POOL_TYPE[$id]:-?} title=${POOL_TITLE[$id]:-?} | válidos=${#POOL_IDS[@]} cola=${remaining} vistos=${seen_count} blacklist=${#BLACKLIST_SET[@]}" >&2
    wallpaper_path "$id"
}

list_engine_pids() {
    local pid exe
    for pid in /proc/[0-9]*; do
        pid=${pid##*/}
        exe=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
        [[ "$exe" == *linux-wallpaperengine ]] || continue
        printf '%s\n' "$pid"
    done
}

stop_pids() {
    local pid
    for pid in "$@"; do
        [[ -n "$pid" ]] || continue
        kill -0 "$pid" 2>/dev/null || continue
        kill -KILL "$pid" 2>/dev/null || true
    done
}

engine_layer_ready() {
    local pid="$1"
    hyprctl layers -j 2>/dev/null | jq -e --argjson pid "$pid" '
        any(.[]; (.levels // {})[][]? | select(.namespace == "linux-wallpaperengine" and .pid == $pid))
    ' >/dev/null 2>&1
}

wait_engine_ready() {
    local pid="$1" i
    for ((i = 0; i < READY_TIMEOUT * 10; i++)); do
        if ! kill -0 "$pid" 2>/dev/null; then
            return 1
        fi
        if engine_layer_ready "$pid"; then
            sleep 0.25
            kill -0 "$pid" 2>/dev/null || return 1
            return 0
        fi
        sleep 0.1
    done
    return 1
}

wait_new_alive() {
    local new_pid="$1" i
    for ((i = 0; i < 50; i++)); do
        kill -0 "$new_pid" 2>/dev/null && return 0
        sleep 0.1
    done
    return 1
}

# El nuevo está listo solo cuando SU layer existe, no cuando hay 2 procesos.
wait_handoff() {
    local new_pid="$1"
    shift
    local -a old_pids=("$@")
    local i pid old_alive

    wait_new_alive "$new_pid" || return 1

    for ((i = 0; i < READY_TIMEOUT * 20; i++)); do
        if ! kill -0 "$new_pid" 2>/dev/null; then
            return 1
        fi

        if engine_layer_ready "$new_pid"; then
            return 0
        fi

        old_alive=false
        for pid in "${old_pids[@]+"${old_pids[@]}"}"; do
            if kill -0 "$pid" 2>/dev/null; then
                old_alive=true
                break
            fi
        done
        if ! $old_alive; then
            kill -0 "$new_pid" 2>/dev/null || return 1
            return 0
        fi

        sleep 0.05
    done
    return 1
}

confirm_wallpaper_alive() {
    local pid="$1"
    sleep "$SETTLE_SECONDS"
    kill -0 "$pid" 2>/dev/null || return 1
    engine_layer_ready "$pid"
}

collect_engine_pids() {
    local -a found=()
    local pid known p

    if [[ -f "$ENGINE_PID_FILE" ]]; then
        pid=$(<"$ENGINE_PID_FILE")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            found+=("$pid")
        fi
    fi

    while read -r pid; do
        [[ -n "$pid" ]] || continue
        known=false
        for p in "${found[@]+"${found[@]}"}"; do
            if [[ "$p" == "$pid" ]]; then
                known=true
                break
            fi
        done
        if ! $known; then
            found+=("$pid")
        fi
    done < <(list_engine_pids)

    printf '%s\n' "${found[@]+"${found[@]}"}"
}

start_engine() {
    local wallpaper="$1"

    /usr/bin/linux-wallpaperengine \
        --layer background \
        --fps 30 \
        --fullscreen-pause-only-active \
        --assets-dir "$ASSETS" \
        --screen-root "$MONITOR" \
        --bg "$wallpaper" </dev/null >/dev/null 2>&1 8>&- 9>&- &

    ENGINE_CHILD_PID=$!
    disown "$ENGINE_CHILD_PID" 2>/dev/null || true
}

keep_only_engine() {
    local keep_pid="$1" other
    while read -r other; do
        [[ -n "$other" && "$other" != "$keep_pid" ]] || continue
        stop_pids "$other"
    done < <(list_engine_pids)
}

try_start_wallpaper() {
    local wallpaper="$1"
    local new_pid
    local -a old_pids=()

    mapfile -t old_pids < <(collect_engine_pids)
    start_engine "$wallpaper"
    new_pid=$ENGINE_CHILD_PID

    if ((${#old_pids[@]} == 0)); then
        if ! wait_engine_ready "$new_pid"; then
            stop_pids "$new_pid"
            return 1
        fi
    else
        if ! wait_handoff "$new_pid" "${old_pids[@]}"; then
            stop_pids "$new_pid"
            return 1
        fi
    fi

    # Esperar un segundo: CEF/web a menudo crashea justo después de crear la layer.
    if ! confirm_wallpaper_alive "$new_pid"; then
        stop_pids "$new_pid"
        return 1
    fi

    if ((${#old_pids[@]} > 0)); then
        stop_pids "${old_pids[@]}"
    fi

    keep_only_engine "$new_pid"
    if ! kill -0 "$new_pid" 2>/dev/null; then
        return 1
    fi

    echo "$new_pid" >"$ENGINE_PID_FILE"
    echo "$wallpaper" >"$CURRENT_WALLPAPER_FILE"
    echo "Wallpaper listo: $wallpaper (pid $new_pid)"
}

dump_stats() {
    load_pool
    sync_queue
    local remaining seen_count
    remaining=$(read_ids "$QUEUE_FILE" | grep -c . || true)
    seen_count=$(read_ids "$SEEN_FILE" | grep -c . || true)
    echo "workshop=$WORKSHOP"
    echo "válidos=${#POOL_IDS[@]}"
    echo "blacklist=${#BLACKLIST_SET[@]}"
    echo "cola_restante=$remaining"
    echo "vistos_ciclo=$seen_count"
    echo "actual=$(current_wallpaper_id || true)"
    echo "queue_file=$QUEUE_FILE"
    echo "seen_file=$SEEN_FILE"
}

main() {
    local wallpaper attempt
    local started=0

    exec 8>"$CHANGE_LOCK"
    if ! flock -w "$CHANGE_TIMEOUT" 8; then
        echo "ERROR: Timeout esperando turno para cambiar wallpaper" >&2
        exit 1
    fi

    load_pool
    echo "Pool: ${#POOL_IDS[@]} wallpapers válidos, blacklist=${#BLACKLIST_SET[@]}" >&2

    for ((attempt = 1; attempt <= MAX_LOAD_ATTEMPTS; attempt++)); do
        wallpaper=$(pick_wallpaper)
        if try_start_wallpaper "$wallpaper"; then
            started=1
            break
        fi
        echo "No cargó $(basename "$wallpaper") (intento $attempt/$MAX_LOAD_ATTEMPTS), siguiente de la cola" >&2
    done

    if ((started == 0)); then
        echo "ERROR: Ningún wallpaper de la cola cargó tras $MAX_LOAD_ATTEMPTS intentos" >&2
        exit 1
    fi
}

if [[ "${1:-}" == --stats ]]; then
    dump_stats
    exit 0
fi

main "$@"
