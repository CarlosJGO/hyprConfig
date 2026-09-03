#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk
import sys
import subprocess

color = sys.argv[1] if len(sys.argv) > 1 else "#07201c"
title = sys.argv[2] if len(sys.argv) > 2 else "minimizados-bg"

class BgWin(Gtk.Window):
    def __init__(self, color_hex, title_name):
        super().__init__()
        self.set_title(title_name)
        self.set_wmclass(title_name, title_name)
        
        css = f"window {{ background-color: {color_hex}; }}"
        provider = Gtk.CssProvider()
        provider.load_from_data(css.encode('utf-8'))
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
        self.connect("destroy", Gtk.main_quit)

win = BgWin(color, title)
win.show_all()
Gtk.main()
