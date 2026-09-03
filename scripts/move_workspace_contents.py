#!/usr/bin/env python3

import json
import subprocess
import sys
import time


def run(args, check=True):
    result = subprocess.run(args, capture_output=True, text=True)

    if check and result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip() or f"Command failed: {args}"
        )

    return result.stdout


def hypr_json(command):
    return json.loads(run(["hyprctl", command, "-j"]))


def lua_string(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def dispatch(expr):
    run(["hyprctl", "dispatch", expr])


def workspace_target(name):
    if not isinstance(name, str) or not name:
        return None

    if name.startswith("special:"):
        return None

    if name.isdigit() or name.startswith("name:"):
        return name

    return f"name:{name}"


def move_window(address, workspace):
    target = workspace_target(workspace)

    if target is None:
        return False

    dispatch(
        'hl.dsp.window.move({'
        f'window="address:{lua_string(address)}", '
        f'workspace="{lua_string(target)}", '
        'follow=false'
        '})'
    )

    return True


def focus_workspace(workspace):
    target = workspace_target(workspace)

    if target is None:
        return

    dispatch(
        'hl.dsp.focus({'
        f'workspace="{lua_string(target)}"'
        '})'
    )


def get_workspace_windows(workspace_id):
    clients = hypr_json("clients")

    return [
        client
        for client in clients
        if client.get("mapped")
        and not client.get("hidden")
        and client.get("address")
        and (client.get("workspace") or {}).get("id") == workspace_id
        and not client.get("pinned")
    ]


def move_all(windows, target):
    for window in windows:
        move_window(window["address"], target)


def swap_workspaces(
    current_id,
    target_id,
    current_windows,
    target_windows,
):
    """
    Swap all non-pinned windows between two workspaces.

    A temporary workspace is used so the two groups never get mixed.
    """

    temporary_id = 9999

    existing_ids = {
        (client.get("workspace") or {}).get("id")
        for client in hypr_json("clients")
    }

    while temporary_id in existing_ids:
        temporary_id -= 1

    temporary = str(temporary_id)
    current = str(current_id)
    target = str(target_id)

    # Current → temporary
    move_all(current_windows, temporary)

    # Target → current
    move_all(target_windows, current)

    # Temporary → target
    move_all(current_windows, target)

    time.sleep(0.05)

    focus_workspace(target)


def move_workspace_contents(direction, max_workspace):
    active = hypr_json("activeworkspace")

    current_id = active.get("id")
    current_name = active.get("name")

    if not isinstance(current_id, int):
        raise RuntimeError(
            "No se pudo determinar el workspace actual"
        )

    if not current_name or current_name.startswith("special:"):
        raise RuntimeError(
            "El workspace actual es especial; operación cancelada"
        )

    target_id = current_id + direction

    # ─────────────────────────────────────────────
    # LÍMITES DE WORKSPACES
    # ─────────────────────────────────────────────

    if target_id < 1 or target_id > max_workspace:
        return

    current_windows = get_workspace_windows(current_id)
    target_windows = get_workspace_windows(target_id)

    # Nada que mover.
    if not current_windows:
        focus_workspace(str(target_id))
        return

    # Destino vacío → movimiento normal.
    if not target_windows:
        move_all(
            current_windows,
            str(target_id),
        )

        time.sleep(0.05)

        focus_workspace(str(target_id))
        return

    # Destino ocupado → intercambio.
    swap_workspaces(
        current_id,
        target_id,
        current_windows,
        target_windows,
    )


def main():
    if len(sys.argv) != 3:
        print(
            f"Uso: {sys.argv[0]} <-1|+1> <max_workspace>",
            file=sys.stderr,
        )
        sys.exit(1)

    if sys.argv[1] not in ("-1", "+1"):
        print(
            f"Dirección inválida: {sys.argv[1]}",
            file=sys.stderr,
        )
        sys.exit(1)

    try:
        direction = int(sys.argv[1])
        max_workspace = int(sys.argv[2])
    except ValueError:
        print(
            "El máximo de workspace debe ser un número.",
            file=sys.stderr,
        )
        sys.exit(1)

    if max_workspace < 1:
        print(
            "El máximo de workspace debe ser mayor que 0.",
            file=sys.stderr,
        )
        sys.exit(1)

    move_workspace_contents(
        direction,
        max_workspace,
    )


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, json.JSONDecodeError, OSError) as error:
        print(
            f"move_workspace_contents: {error}",
            file=sys.stderr,
        )
        sys.exit(1)