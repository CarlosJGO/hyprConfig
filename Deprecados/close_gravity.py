#!/usr/bin/env python3

import json
import math
import subprocess
import sys
import time


FPS = 60
FRAME_TIME = 1 / FPS

# Duración aproximada del efecto.
DURATION = 0.42

# Qué tan abajo sale disparada.
FALL_DISTANCE = 420

# Rotación NO está expuesta por Hyprland, así que simulamos
# la sensación de giro mediante aceleración + escala + movimiento.
MIN_SCALE = 0.55


def run(args, check=True):
    result = subprocess.run(
        args,
        capture_output=True,
        text=True,
    )

    if check and result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip()
            or f"Command failed: {args}"
        )

    return result.stdout


def hypr_json(command):
    return json.loads(
        run(["hyprctl", command, "-j"])
    )


def lua_string(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def dispatch(expr):
    run(["hyprctl", "dispatch", expr])


def window_prop(address, prop, value):
    dispatch(
        'hl.dsp.window.set_prop({'
        f'window="address:{lua_string(address)}", '
        f'prop="{prop}", '
        f'value="{value}"'
        '})'
    )


def move_window(address, x, y):
    dispatch(
        'hl.dsp.window.move({'
        f'window="address:{lua_string(address)}", '
        f'x={x}, '
        f'y={y}, '
        'relative=false'
        '})'
    )


def resize_window(address, width, height):
    dispatch(
        'hl.dsp.window.resize({'
        f'window="address:{lua_string(address)}", '
        f'x={width}, '
        f'y={height}, '
        'relative=false'
        '})'
    )


def kill_window(address):
    dispatch(
        'hl.dsp.window.kill({'
        f'window="address:{lua_string(address)}"'
        '})'
    )


def ease_in(t):
    """
    Aceleración tipo gravedad.
    """
    return t * t


def get_active_window():
    return hypr_json("activewindow")


def gravity_close():
    window = get_active_window()

    address = window.get("address")

    if not address:
        return

    if window.get("pinned"):
        return

    pos = window.get("at")

    size = window.get("size")

    if not pos or not size:
        kill_window(address)
        return

    original_x = int(pos[0])
    original_y = int(pos[1])

    original_w = int(size[0])
    original_h = int(size[1])

    # Guardamos el centro para que el encogimiento parezca
    # ocurrir hacia el centro de la ventana.
    center_x = original_x + original_w / 2
    center_y = original_y + original_h / 2

    # Aseguramos que la ventana pueda recibir modificaciones
    # visuales durante el efecto.
    window_prop(address, "alphaoverride", "1")

    frames = max(
        1,
        int(DURATION * FPS),
    )

    try:
        for frame in range(frames):
            t = frame / (frames - 1)

            # Gravedad:
            # empieza despacio y acelera progresivamente.
            fall = ease_in(t) * FALL_DISTANCE

            # Pequeño desplazamiento lateral para darle sensación
            # de que la ventana "sale disparada".
            side = math.sin(t * math.pi) * 45

            # Encogimiento.
            scale = 1 - ((1 - MIN_SCALE) * t)

            width = max(
                1,
                int(original_w * scale),
            )

            height = max(
                1,
                int(original_h * scale),
            )

            # Mantener el centro aproximadamente fijo mientras
            # cambia el tamaño.
            x = int(
                center_x
                - width / 2
                + side
            )

            y = int(
                center_y
                - height / 2
                + fall
            )

            # Desaparición progresiva.
            alpha = max(
                0.0,
                1.0 - (t ** 1.7),
            )

            move_window(
                address,
                x,
                y,
            )

            resize_window(
                address,
                width,
                height,
            )

            window_prop(
                address,
                "alpha",
                f"{alpha:.3f}",
            )

            time.sleep(FRAME_TIME)

    finally:
        # Ya no importa restaurar las propiedades porque
        # la ventana va a desaparecer.
        kill_window(address)


def main():
    gravity_close()


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(
            f"close_gravity: {error}",
            file=sys.stderr,
        )
        sys.exit(1)