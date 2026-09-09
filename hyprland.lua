-- CachyOS Hyprland Configuration

require("config.animations")
require("config.hyprfocus")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.environment")
require("config.inputs")
require("config.binds")
require("config.juguetes")
require("config.misc")
require("config.monitors")
require("config.windowrules")
require("config.float_place")
require("config.workspaces")

-- For Noctalia Color templates
require("noctalia").apply_theme()

-- Generated from Jugoo's active semantic theme; keep this last.
require("config.jugoo_theme_generated").apply()

