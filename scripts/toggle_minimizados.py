#!/usr/bin/env python3
"""Move focused windows to/from the ``special:minimizados`` workspace.

The state file deliberately uses a Hyprland client address as its key. An
address identifies a running window, so records vanish naturally when that
window closes and cannot accidentally be applied to another window.
"""

import json
import subprocess
import sys
import time
from pathlib import Path


STATE_FILE = Path.home() / ".config" / "hypr" / "minimizados-state.json"
MINIMIZADOS_WS = "special:minimizados"
DEFAULT_WORKSPACE = "1"


def run(args, check=True):
    result = subprocess.run(args, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"Command failed: {args}")
    return result.stdout


def hypr_json(command):
    return json.loads(run(["hyprctl", command, "-j"]))


def load_state():
    if not STATE_FILE.exists():
        return {"windows": {}}
    try:
        state = json.loads(STATE_FILE.read_text())
    except (json.JSONDecodeError, OSError):
        return {"windows": {}}
    windows = state.get("windows")
    return {"windows": windows if isinstance(windows, dict) else {}}


def save_state(state):
    windows = state.get("windows", {})
    if not windows:
        try:
            STATE_FILE.unlink()
        except FileNotFoundError:
            pass
        return
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps({"windows": windows}, indent=2) + "\n")


def is_minimizados_workspace(name):
    return name in (MINIMIZADOS_WS, "minimizados", "name:minimizados")


def workspace_target(name):
    """Return a safe Hyprland workspace selector, or None for bad state."""
    if not isinstance(name, str) or not name or is_minimizados_workspace(name):
        return None
    if name.startswith("special:"):
        return None
    if name.isdigit() or name.startswith("name:"):
        return name
    return f"name:{name}"


def lua_string(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def dispatch(expr):
    run(["hyprctl", "dispatch", expr])


def move_window(address, workspace, follow=False):
    target = workspace_target(workspace)
    if target is None and workspace != MINIMIZADOS_WS:
        return False
    if workspace == MINIMIZADOS_WS:
        target = MINIMIZADOS_WS
    follow_value = "true" if follow else "false"
    dispatch(
        'hl.dsp.window.move({'
        f'window="address:{lua_string(address)}", '
        f'workspace="{lua_string(target)}", follow={follow_value}'
        '})'
    )
    return True


def visible_special_host():
    """Whether minimizados is currently open on any monitor."""
    for monitor in hypr_json("monitors"):
        special = (monitor.get("specialWorkspace") or {}).get("name")
        if is_minimizados_workspace(special):
            return True
    return False


def close_special():
    # A special workspace may be visible on another monitor. Close it before
    # focusing a restored client so focus lands on its actual origin workspace.
    for _ in range(2):
        if not visible_special_host():
            return
        dispatch('hl.dsp.workspace.toggle_special("minimizados")')
        time.sleep(0.12)


def notify(message):
    # Notification is best-effort: failure to show it must never block a move.
    run(["hyprctl", "notify", "-1", "3500", "0", message], check=False)


def managed_special_clients(state, clients):
    special_clients = {
        client.get("address"): client
        for client in clients
        if client.get("address")
        and is_minimizados_workspace(client.get("workspace", {}).get("name"))
    }
    # Drop records for closed or manually moved windows, but never take over
    # windows that happened to be placed in minimizados by another mechanism.
    state["windows"] = {
        address: origin
        for address, origin in state["windows"].items()
        if address in special_clients
    }
    return special_clients


def minimize_focused():
    focused = hypr_json("activewindow")
    address = focused.get("address")
    focused_workspace = (focused.get("workspace") or {}).get("name")
    # Hyprland can report the normal workspace beneath an open special as the
    # active workspace, so the focused client's workspace is authoritative.
    if is_minimizados_workspace(focused_workspace):
        return restore_focused(focused)

    active_workspace = hypr_json("activeworkspace").get("name")
    if not address or focused_workspace != active_workspace:
        notify("Minimizados: no hay una ventana enfocada en este workspace")
        return
    if focused.get("pinned"):
        notify("Minimizados: no se puede minimizar una ventana fijada")
        return
    if workspace_target(active_workspace) is None:
        notify("Minimizados: el workspace de origen no es válido")
        return

    state = load_state()
    managed_special_clients(state, hypr_json("clients"))
    # Store before dispatching so an immediately-opened special workspace still
    # has the exact origin for this client.
    state["windows"][address] = active_workspace
    save_state(state)
    move_window(address, MINIMIZADOS_WS, follow=False)


def origin_or_fallback(origin):
    target = workspace_target(origin)
    if target is not None:
        # Moving to a normal workspace recreates it if Hyprland had removed it
        # after its last window left, which preserves the user's original ID.
        return origin, False
    return DEFAULT_WORKSPACE, True


def restore_focused(focused=None):
    focused = focused or hypr_json("activewindow")
    address = focused.get("address")
    focused_workspace = (focused.get("workspace") or {}).get("name")
    if not address or not is_minimizados_workspace(focused_workspace):
        notify("Minimizados: enfoca una ventana dentro de special:minimizados")
        return

    state = load_state()
    managed_special_clients(state, hypr_json("clients"))
    origin = state["windows"].get(address)
    if origin is None:
        save_state(state)
        notify("Minimizados: ventana sin origen registrado; no se movió")
        return

    target, used_fallback = origin_or_fallback(origin)
    move_window(address, target, follow=False)
    del state["windows"][address]
    save_state(state)
    close_special()
    # Explicitly focus the target after closing the overlay. This works even
    # when the original workspace had become empty and was recreated above.
    dispatch(f'hl.dsp.focus({{workspace="{lua_string(workspace_target(target))}"}})')
    if used_fallback:
        notify("Minimizados: origen inválido; ventana restaurada en workspace 1")


def restore_all():
    state = load_state()
    special_clients = managed_special_clients(state, hypr_json("clients"))
    fallback_count = 0

    for address, origin in list(state["windows"].items()):
        if address not in special_clients:
            continue
        target, used_fallback = origin_or_fallback(origin)
        move_window(address, target, follow=False)
        fallback_count += used_fallback
        del state["windows"][address]

    save_state(state)
    if fallback_count:
        notify(f"Minimizados: {fallback_count} ventana(s) restaurada(s) en workspace 1 por origen inválido")


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "restore-all":
        restore_all()
    else:
        minimize_focused()


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, json.JSONDecodeError, OSError) as error:
        notify(f"Minimizados: error: {error}")
