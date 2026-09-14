#!/usr/bin/env python3
"""Solid-color backgrounds for special workspaces.

Creates layer-shell surfaces on the background layer (above the wallpaper
via the "hypr-special-bg" layer rule) and shows/hides them following
Hyprland's activespecial events, so each special workspace gets its own
background color.
"""
import json
import os
import signal
import socket
import subprocess
import threading

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

signal.signal(signal.SIGINT, signal.SIG_DFL)
signal.signal(signal.SIGTERM, signal.SIG_DFL)

# No solid surfaces: special workspaces show the wallpaper through the light blur.
COLORS = {}
NAMESPACE = "hypr-special-bg"

# surfaces[monitor_name][special_name] = Gtk.Window
surfaces = {}


def get_dim_factor():
    """Fraction of brightness that survives decoration:dim_special."""
    try:
        out = subprocess.run(["hyprctl", "getoption", "decoration:dim_special", "-j"],
                             capture_output=True, text=True).stdout
        data = json.loads(out)
        dim = float(data.get("float", data.get("int", 0)))
        return max(1.0 - dim, 0.05)
    except (ValueError, TypeError, KeyError):
        return 1.0


def compensate(hex_color, factor):
    """Brighten a color so it still looks like hex_color after dim_special."""
    hex_color = hex_color.lstrip("#")
    rgb = [int(hex_color[i:i + 2], 16) for i in (0, 2, 4)]
    rgb = [min(255, round(c / factor)) for c in rgb]
    return "#{:02x}{:02x}{:02x}".format(*rgb)


def get_gdk_monitor(connector):
    display = Gdk.Display.get_default()
    for i in range(display.get_n_monitors()):
        monitor = display.get_monitor(i)
        if monitor.get_model() == connector:
            return monitor
    return None


def get_surface(monitor_name, special_name):
    per_monitor = surfaces.setdefault(monitor_name, {})
    win = per_monitor.get(special_name)
    if win is not None:
        return win

    win = Gtk.Window()
    win.set_app_paintable(True)

    color = Gdk.RGBA()
    color.parse(compensate(COLORS[special_name], get_dim_factor()))

    area = Gtk.DrawingArea()
    area.set_size_request(100, 100)

    def on_draw(widget, cr, rgba=color):
        cr.set_source_rgb(rgba.red, rgba.green, rgba.blue)
        cr.paint()
        return False

    area.connect("draw", on_draw)
    win.add(area)

    GtkLayerShell.init_for_window(win)
    gdk_monitor = get_gdk_monitor(monitor_name)
    if gdk_monitor is not None:
        GtkLayerShell.set_monitor(win, gdk_monitor)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.BOTTOM)
    GtkLayerShell.set_namespace(win, NAMESPACE)
    for edge in (GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT,
                 GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM):
        GtkLayerShell.set_anchor(win, edge, True)
    GtkLayerShell.set_exclusive_zone(win, -1)

    per_monitor[special_name] = win
    return win


def set_special(monitor_name, special_name):
    for name, win in surfaces.get(monitor_name, {}).items():
        if name != special_name:
            win.hide()
    if special_name in COLORS:
        get_surface(monitor_name, special_name).show_all()


def handle_event(line):
    if not line.startswith("activespecial"):
        return
    payload = line.split(">>", 1)[1]
    parts = [p.strip() for p in payload.split(",")]
    monitor = parts[-1] if parts else ""
    special = next((p for p in parts if p.startswith("special:")), "")
    if monitor:
        GLib.idle_add(set_special, monitor, special)


def socket_path():
    his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    for candidate in (f"{runtime}/hypr/{his}/.socket2.sock",
                      f"/tmp/hypr/{his}/.socket2.sock"):
        if os.path.exists(candidate):
            return candidate
    return f"{runtime}/hypr/{his}/.socket2.sock"


def listen():
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
                sock.connect(socket_path())
                buf = b""
                while True:
                    chunk = sock.recv(4096)
                    if not chunk:
                        break
                    buf += chunk
                    while b"\n" in buf:
                        line, buf = buf.split(b"\n", 1)
                        handle_event(line.decode(errors="replace").strip())
        except OSError:
            pass
        threading.Event().wait(2)


def sync_initial():
    out = subprocess.run(["hyprctl", "monitors", "-j"],
                         capture_output=True, text=True).stdout
    for monitor in json.loads(out):
        special = (monitor.get("specialWorkspace") or {}).get("name") or ""
        set_special(monitor.get("name"), special)


def main():
    threading.Thread(target=listen, daemon=True).start()
    GLib.idle_add(sync_initial)
    Gtk.main()


if __name__ == "__main__":
    main()
