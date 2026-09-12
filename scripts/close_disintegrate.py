#!/usr/bin/env python3

"""Disintegrate a Hyprland window or an arbitrary screen region (Jugoo layers).

Modes:
  (default)           Capture active/target window → overlay → close
  --overlay-only -g   Capture geometry → overlay only (caller hides the UI)
"""

import argparse
import json
import os
import secrets
import subprocess
import sys
import tempfile
import time


DURATION_MS = int(os.environ.get("HYPR_DISINTEGRATE_DURATION_MS", "550"))
BLOCK_SIZE = float(os.environ.get("HYPR_DISINTEGRATE_BLOCK_SIZE", "0.018"))
INTENSITY = float(os.environ.get("HYPR_DISINTEGRATE_INTENSITY", "1.05"))
READY_TIMEOUT_S = float(os.environ.get("HYPR_DISINTEGRATE_READY_TIMEOUT", "0.9"))


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
        time.sleep(0.008)
    return False


def show_overlay(geometry, image_path, monitor=None, ready_path=None):
    x, y = geometry["at"]
    width, height = geometry["size"]
    if monitor is None:
        monitor = monitor_for_point(int(x), int(y))
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
            "HYPR_DISINTEGRATE_DURATION": str(DURATION_MS),
            "HYPR_DISINTEGRATE_BLOCK": str(BLOCK_SIZE),
            "HYPR_DISINTEGRATE_INTENSITY": str(INTENSITY),
            "HYPR_DISINTEGRATE_SEED": str(secrets.randbelow(10000)),
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


def run_overlay_only(geometry_spec):
    """Capture → wait for plate → return (caller may hide UI without a gap)."""
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
        show_overlay(geometry, image_path, ready_path=ready_path)
        wait_until_ready(ready_path)
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


def run_window_close():
    window = target_window()
    address = window.get("address")
    image_path = None
    ready_path = None
    try:
        if not address or window.get("pinned"):
            close_natively(address)
            return

        with tempfile.NamedTemporaryFile(
            prefix="hypr-disintegrate-", suffix=".png", delete=False
        ) as image:
            image_path = image.name

        geometry = {"at": window["at"], "size": window["size"], "monitor": window.get("monitor", 0)}
        monitors = json.loads(run(["hyprctl", "monitors", "-j"]))
        monitor_id = window.get("monitor", 0)
        monitor = next(
            (item for item in monitors if item.get("id") == monitor_id),
            monitors[monitor_id] if monitor_id < len(monitors) else monitors[0],
        )

        # 1) Snapshot while the live window is still fully visible.
        capture_geometry(geometry, image_path)
        ready_path = make_ready_path()
        # 2) Bring the overlay plate up ON TOP of the still-visible window.
        show_overlay(geometry, image_path, monitor=monitor, ready_path=ready_path)
        wait_until_ready(ready_path)
        # 3) Only now hide/close — the plate already covers the same pixels.
        prepare_silent_close(address)
        close_natively(address)
        image_path = None
    except Exception as error:
        print(f"close_disintegrate: {error}", file=sys.stderr)
        if address:
            try:
                close_silently(address)
            except Exception as fallback_error:
                print(f"close_disintegrate fallback: {fallback_error}", file=sys.stderr)
        if image_path:
            try:
                os.unlink(image_path)
            except FileNotFoundError:
                pass
    finally:
        if ready_path:
            try:
                os.unlink(ready_path)
            except FileNotFoundError:
                pass


def main():
    parser = argparse.ArgumentParser(description="Window / layer disintegration close")
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
    args = parser.parse_args()

    if args.overlay_only:
        if not args.geometry:
            print("close_disintegrate: --geometry required with --overlay-only", file=sys.stderr)
            sys.exit(2)
        try:
            run_overlay_only(args.geometry)
        except Exception as error:
            print(f"close_disintegrate: {error}", file=sys.stderr)
            sys.exit(1)
        return

    run_window_close()


if __name__ == "__main__":
    main()
