#!/usr/bin/env python3
"""
Cierre inteligente:
- Flotante → cierre nativo (caída gravity / slide bottom).
- Tiled → fade suave in-place; el hueco del layout se mantiene
  hasta que la ventana ya no es visible, luego el resto se expande.
"""

import json
import subprocess
import sys
import time

FPS = 60
FRAME_TIME = 1 / FPS
DURATION = 0.38


def run(args, check=True):
    result = subprocess.run(args, capture_output=True, text=True)
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"Command failed: {args}")
    return result.stdout


def hypr_json(command):
    return json.loads(run(["hyprctl", command, "-j"]))


def lua_string(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def dispatch(expr):
    run(["hyprctl", "dispatch", expr])


def window_prop(address, prop, value):
    dispatch(
        "hl.dsp.window.set_prop({"
        f'window="address:{lua_string(address)}", '
        f'prop="{prop}", '
        f'value="{value}"'
        "})"
    )


def close_window(address):
    dispatch(
        "hl.dsp.window.close({"
        f'window="address:{lua_string(address)}"'
        "})"
    )


def kill_window(address):
    dispatch(
        "hl.dsp.window.kill({"
        f'window="address:{lua_string(address)}"'
        "})"
    )


def smoothstep(t):
    return t * t * (3.0 - 2.0 * t)


def soft_tiled_close(address):
    """Fade in-place while still tiled, then kill (layout reflows after)."""
    window_prop(address, "alphaoverride", "1")
    # Evita que el kill dispare otra animación de salida visible.
    window_prop(address, "animationstyle", "none")
    window_prop(address, "noanim", "1")

    frames = max(1, int(DURATION * FPS))

    try:
        for frame in range(frames):
            t = frame / max(1, frames - 1)
            alpha = max(0.0, 1.0 - smoothstep(t))
            window_prop(address, "alpha", f"{alpha:.3f}")
            time.sleep(FRAME_TIME)
    finally:
        kill_window(address)


def main():
    window = hypr_json("activewindow")
    address = window.get("address")

    if not address:
        return

    if window.get("pinned"):
        close_window(address)
        return

    if window.get("floating"):
        # Caída nativa (windowsOut gravity + slide bottom).
        close_window(address)
        return

    soft_tiled_close(address)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"close_smart: {error}", file=sys.stderr)
        sys.exit(1)
