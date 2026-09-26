#!/usr/bin/env python3

"""Close-effect launcher for Hyprland windows / Jugoo layer regions.

Modes:
  (default)           Capture active/target window → overlay → close (async)
  --overlay-only -g   Capture geometry → overlay only (NEVER closes any window)
  --effect NAME       Force one catalog entry (default: random pick)

Critical: --overlay-only must never call activewindow/close. Jugoo popups use it
when dismissing; a regression here closes whatever has Hyprland focus.

Catalog mirrors WINDOW_IN_EFFECTS in animations.lua: add a row (+ .frag/.qsb)
to WINDOW_OUT_EFFECTS for a new disappear effect.
"""

import argparse
import fcntl
import json
import os
import secrets
import subprocess
import sys
import tempfile
import time

CLOSING_TAG = "closing"


READY_TIMEOUT_S = float(os.environ.get("HYPR_DISINTEGRATE_READY_TIMEOUT", "0.9"))

# Catálogo de salidas. Añade una fila (y su .frag/.qsb) para un efecto nuevo.
# Hyprland no puede shader-ear la ventana real: capturamos → overlay → close.
WINDOW_OUT_EFFECTS = [
    {
        "name": "desintegra",
        "shader": "disintegrate.frag.qsb",
        "duration_ms": 550,
        "block_size": 0.018,
        "intensity": 1.05,
    },
    {
        "name": "tornado",
        "shader": "tornado.frag.qsb",
        "duration_ms": 780,
        "block_size": 0.018,
        "intensity": 1.15,
    },
]


def effect_by_name(name):
    needle = (name or "").strip().lower()
    for effect in WINDOW_OUT_EFFECTS:
        if effect["name"] == needle:
            return effect
    return None


def pick_effect(forced=None):
    """Random pick like WINDOW_IN_EFFECTS, unless forced via --effect / env."""
    forced = forced or os.environ.get("HYPR_CLOSE_EFFECT")
    if forced:
        effect = effect_by_name(forced)
        if effect is None:
            names = ", ".join(item["name"] for item in WINDOW_OUT_EFFECTS)
            raise RuntimeError(f"unknown effect {forced!r}; choose one of: {names}")
        return effect
    return secrets.choice(WINDOW_OUT_EFFECTS)


def effect_duration_ms(effect):
    override = os.environ.get("HYPR_DISINTEGRATE_DURATION_MS")
    if override:
        return int(override)
    return int(effect["duration_ms"])


def effect_block_size(effect):
    override = os.environ.get("HYPR_DISINTEGRATE_BLOCK_SIZE")
    if override:
        return float(override)
    return float(effect["block_size"])


def effect_intensity(effect):
    override = os.environ.get("HYPR_DISINTEGRATE_INTENSITY")
    if override:
        return float(override)
    return float(effect["intensity"])


def run(command, check=True):
    result = subprocess.run(command, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "command failed")
    return result.stdout


def dispatch(expression):
    run(["hyprctl", "dispatch", expression])


def set_prop(address, prop, value):
    dispatch(
        "hl.dsp.window.set_prop({"
        f'window="address:{address}", prop="{prop}", value="{value}"'
        "})"
    )


def close_natively(address=None):
    expression = "hl.dsp.window.close()"
    if address:
        expression = f'hl.dsp.window.close({{window="address:{address}"}})'
    dispatch(expression)


def prepare_silent_close(address):
    for prop, value in (
        ("animationstyle", "none"),
        ("noanim", "1"),
        ("no_anim", "1"),
        ("alphaoverride", "1"),
        ("alpha", "0"),
    ):
        try:
            set_prop(address, prop, value)
        except RuntimeError as error:
            print(f"close_disintegrate prep {prop}: {error}", file=sys.stderr)


def close_silently(address):
    prepare_silent_close(address)
    close_natively(address)


def window_tags(window):
    tags = window.get("tags") or []
    if isinstance(tags, str):
        return [tags]
    return [str(tag) for tag in tags]


def is_closing_window(window):
    return CLOSING_TAG in window_tags(window)


def tag_window(address, tag):
    dispatch(
        "hl.dsp.window.tag({"
        f'window="address:{address}", tag="{tag}"'
        "})"
    )


def focus_away_from(address, workspace_id=None):
    """Move focus off the dying window so SUPER+Q cannot retarget it."""
    try:
        clients = json.loads(run(["hyprctl", "clients", "-j"]))
    except RuntimeError:
        clients = []
    candidates = []
    for client in clients:
        if client.get("address") == address:
            continue
        if is_closing_window(client):
            continue
        if client.get("hidden"):
            continue
        if workspace_id is not None:
            ws = client.get("workspace") or {}
            if ws.get("id") != workspace_id:
                continue
        candidates.append(client)
    candidates.sort(key=lambda item: item.get("focusHistoryID", 10**9))
    if candidates:
        other = candidates[0]["address"]
        try:
            dispatch(f'hl.dsp.focus({{window="address:{other}"}})')
            return
        except RuntimeError as error:
            print(f"close_disintegrate focus: {error}", file=sys.stderr)
    try:
        dispatch('hl.dsp.focus({direction="r"})')
    except RuntimeError as error:
        print(f"close_disintegrate focus fallback: {error}", file=sys.stderr)


def seize_closing_window(address, workspace_id=None):
    """Mark window as in-flight: no focus, no retarget, click-through-ish.

    Intentionally avoid forcing focus to another client here: that side effect is
    what causes the mouse to jump to a different window while the close effect is
    still playing.
    """
    try:
        tag_window(address, f"+{CLOSING_TAG}")
    except RuntimeError as error:
        print(f"close_disintegrate tag: {error}", file=sys.stderr)
    for prop, value in (
        ("no_focus", "1"),
        ("no_follow_mouse", "1"),
        ("focus_on_activate", "0"),
    ):
        try:
            set_prop(address, prop, value)
        except RuntimeError as error:
            print(f"close_disintegrate seize {prop}: {error}", file=sys.stderr)


def active_window():
    return json.loads(run(["hyprctl", "activewindow", "-j"]))


def target_window():
    target_address = os.environ.get("HYPR_DISINTEGRATE_TARGET_ADDRESS")
    if not target_address:
        return active_window()
    windows = json.loads(run(["hyprctl", "clients", "-j"]))
    return next(
        (window for window in windows if window.get("address") == target_address),
        {},
    )


def parse_geometry(spec):
    """Parse grim-style geometry: 'x,y wxh'."""
    position, size = spec.strip().split()
    x_s, y_s = position.split(",")
    w_s, h_s = size.lower().split("x")
    return {
        "at": [int(x_s), int(y_s)],
        "size": [int(w_s), int(h_s)],
        "monitor": 0,
    }


def monitor_for_point(x, y):
    monitors = json.loads(run(["hyprctl", "monitors", "-j"]))
    for monitor in monitors:
        mx, my = int(monitor["x"]), int(monitor["y"])
        mw, mh = int(monitor["width"]), int(monitor["height"])
        if mx <= x < mx + mw and my <= y < my + mh:
            return monitor
    return monitors[0]


def capture_geometry(geometry, image_path):
    x, y = geometry["at"]
    width, height = geometry["size"]
    run(["grim", "-g", f"{int(x)},{int(y)} {int(width)}x{int(height)}", image_path])


def make_ready_path():
    handle, path = tempfile.mkstemp(prefix="hypr-disintegrate-ready-", suffix=".flag")
    os.close(handle)
    os.unlink(path)
    return path


def wait_until_ready(ready_path, timeout_s=READY_TIMEOUT_S):
    """Block until the overlay has painted its solid plate (or timeout)."""
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        if os.path.exists(ready_path):
            try:
                os.unlink(ready_path)
            except FileNotFoundError:
                pass
            return True
        time.sleep(0.006)
    return False


def address_lock_path(address):
    safe = address.replace("/", "_").replace(":", "_")
    return f"/tmp/hypr-disintegrate-inflight-{safe}.lock"


def try_claim_address(address):
    """Exclusive flock so double-Q is ignored even after the parent exits.

    PID-based locks were wrong: parent forks and dies, so a second Q treated
    the lock as stale and restarted the effect mid-animation.
    """
    path = address_lock_path(address)
    fd = os.open(path, os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        os.close(fd)
        return None, path
    try:
        os.ftruncate(fd, 0)
        os.lseek(fd, 0, os.SEEK_SET)
        os.write(fd, f"{os.getpid()}\n".encode())
    except OSError:
        pass
    return fd, path


def release_address(lock_fd, path):
    if lock_fd is not None:
        try:
            fcntl.flock(lock_fd, fcntl.LOCK_UN)
        except OSError:
            pass
        try:
            os.close(lock_fd)
        except OSError:
            pass
    if path:
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass


def show_overlay(geometry, image_path, effect, monitor=None, ready_path=None):
    x, y = geometry["at"]
    width, height = geometry["size"]
    if monitor is None:
        monitor = monitor_for_point(int(x), int(y))
    # Tornado reuses BLOCK as aspect (w/h) so the mask is a true circle in pixels.
    block = effect_block_size(effect)
    if effect["name"] == "tornado":
        block = float(width) / max(float(height), 1.0)
    environment = os.environ.copy()
    environment.update(
        {
            "HYPR_DISINTEGRATE_IMAGE": image_path,
            "HYPR_DISINTEGRATE_X": str(int(x)),
            "HYPR_DISINTEGRATE_Y": str(int(y)),
            "HYPR_DISINTEGRATE_WIDTH": str(int(width)),
            "HYPR_DISINTEGRATE_HEIGHT": str(int(height)),
            "HYPR_DISINTEGRATE_MONITOR": str(monitor.get("id", 0)),
            "HYPR_DISINTEGRATE_MONITOR_NAME": str(monitor.get("name", "")),
            "HYPR_DISINTEGRATE_MONITOR_X": str(int(monitor["x"])),
            "HYPR_DISINTEGRATE_MONITOR_Y": str(int(monitor["y"])),
            "HYPR_DISINTEGRATE_DURATION": str(effect_duration_ms(effect)),
            "HYPR_DISINTEGRATE_BLOCK": str(block),
            "HYPR_DISINTEGRATE_INTENSITY": str(effect_intensity(effect)),
            "HYPR_DISINTEGRATE_SEED": str(secrets.randbelow(10000)),
            "HYPR_CLOSE_EFFECT": effect["name"],
            "HYPR_CLOSE_SHADER": effect["shader"],
        }
    )
    if ready_path:
        environment["HYPR_DISINTEGRATE_READY_FILE"] = ready_path
    overlay = os.path.join(os.path.dirname(__file__), "window_disintegrate", "overlay.qml")
    return subprocess.Popen(
        ["qs", "-d", "-p", overlay],
        env=environment,
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def run_overlay_only(geometry_spec, effect):
    """Capture → wait for plate → return. Does NOT close/kill any Hyprland window."""
    geometry = parse_geometry(geometry_spec)
    width, height = geometry["size"]
    if width < 2 or height < 2:
        raise RuntimeError("geometry too small")

    with tempfile.NamedTemporaryFile(
        prefix="hypr-disintegrate-", suffix=".png", delete=False
    ) as image:
        image_path = image.name

    ready_path = make_ready_path()
    try:
        capture_geometry(geometry, image_path)
        show_overlay(geometry, image_path, effect, ready_path=ready_path)
        wait_until_ready(ready_path)
        # Overlay owns image cleanup. Never call close_natively here.
    except Exception:
        try:
            os.unlink(image_path)
        except FileNotFoundError:
            pass
        try:
            os.unlink(ready_path)
        except FileNotFoundError:
            pass
        raise


def _finish_close_after_ready(address, ready_path, lock_fd, lock_path):
    """Child: wait for plate, then close the SNAPSHOTTED address only."""
    try:
        wait_until_ready(ready_path)
        prepare_silent_close(address)
        close_natively(address)
    except Exception as error:
        print(f"close_disintegrate finish: {error}", file=sys.stderr)
        try:
            close_silently(address)
        except Exception as fallback_error:
            print(f"close_disintegrate fallback: {fallback_error}", file=sys.stderr)
    finally:
        if ready_path:
            try:
                os.unlink(ready_path)
            except FileNotFoundError:
                pass
        release_address(lock_fd, lock_path)


def run_window_close(effect):
    window = target_window()
    # Freeze target now — never re-query activewindow after this.
    address = window.get("address")
    if not address or window.get("pinned"):
        close_natively(address)
        return

    if is_closing_window(window):
        # Already seized / animating; never restart the effect.
        return

    lock_fd, lock_path = try_claim_address(address)
    if lock_fd is None:
        # This window is already playing a close effect; ignore duplicate Q.
        return

    image_path = None
    ready_path = None
    workspace_id = (window.get("workspace") or {}).get("id")
    try:
        with tempfile.NamedTemporaryFile(
            prefix="hypr-disintegrate-", suffix=".png", delete=False
        ) as image:
            image_path = image.name

        geometry = {
            "at": window["at"],
            "size": window["size"],
            "monitor": window.get("monitor", 0),
        }
        monitors = json.loads(run(["hyprctl", "monitors", "-j"]))
        monitor_id = window.get("monitor", 0)
        monitor = next(
            (item for item in monitors if item.get("id") == monitor_id),
            monitors[monitor_id] if monitor_id < len(monitors) else monitors[0],
        )

        # Capture while still focused (avoids inactive_opacity looking dim).
        capture_geometry(geometry, image_path)
        ready_path = make_ready_path()
        show_overlay(geometry, image_path, effect, monitor=monitor, ready_path=ready_path)
        # Seize immediately after overlay launch: no second Q / no focus / pass focus.
        seize_closing_window(address, workspace_id=workspace_id)

        # Return the bind immediately: finish close in a child process so the
        # next SUPER+Q can target another window without waiting.
        # flock is inherited; parent must NOT close/unlock the fd.
        pid = os.fork()
        if pid == 0:
            _finish_close_after_ready(address, ready_path, lock_fd, lock_path)
            os._exit(0)

        # Parent: overlay owns the PNG; child owns the lock/ready cleanup.
        # Drop the Python ref without unlocking — child keeps the flock alive.
        image_path = None
        ready_path = None
        lock_fd = None
        lock_path = None
    except Exception as error:
        print(f"close_disintegrate: {error}", file=sys.stderr)
        try:
            close_silently(address)
        except Exception as fallback_error:
            print(f"close_disintegrate fallback: {fallback_error}", file=sys.stderr)
        if image_path:
            try:
                os.unlink(image_path)
            except FileNotFoundError:
                pass
        if ready_path:
            try:
                os.unlink(ready_path)
            except FileNotFoundError:
                pass
        release_address(lock_fd, lock_path)


def main():
    names = ", ".join(effect["name"] for effect in WINDOW_OUT_EFFECTS)
    parser = argparse.ArgumentParser(description="Window / layer close-effect launcher")
    parser.add_argument(
        "--overlay-only",
        action="store_true",
        help="Only play the effect for a screen region (no Hyprland close)",
    )
    parser.add_argument(
        "-g",
        "--geometry",
        help="grim geometry 'x,y wxh' (required with --overlay-only)",
    )
    parser.add_argument(
        "--effect",
        help=f"force effect ({names}); default: random",
    )
    args = parser.parse_args()

    try:
        effect = pick_effect(args.effect)
    except RuntimeError as error:
        print(f"close_disintegrate: {error}", file=sys.stderr)
        sys.exit(2)

    if args.overlay_only:
        if not args.geometry:
            print(
                "close_disintegrate: --geometry required with --overlay-only",
                file=sys.stderr,
            )
            sys.exit(2)
        try:
            run_overlay_only(args.geometry, effect)
        except Exception as error:
            print(f"close_disintegrate: {error}", file=sys.stderr)
            sys.exit(1)
        return

    run_window_close(effect)


if __name__ == "__main__":
    main()
