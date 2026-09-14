-- CachyOS Hyprland Configuration

require("config.animations")
require("config.hyprfocus")
require("config.autostart")
require("config.colors")
require("config.decorations")
require("config.variables")
require("config.environment")
require("config.inputs")
require("config.consume_fs")
require("config.binds")
require("config.juguetes")
require("config.misc")
require("config.monitors")
require("config.windowrules")
require("config.jugoo_popup_place")
require("config.float_place")
require("config.workspaces")

-- Generated from Jugoo's active semantic theme; keep this last.
require("config.jugoo_theme_generated").apply()

-- Keep special workspaces transparent with the lightest supported blur.
hl.config({
	decoration = {
		blur = {
			enabled = true,
			size = 1,
			passes = 1,
			special = true,
		},
	},
})

