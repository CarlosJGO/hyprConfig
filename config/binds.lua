local mainMod = "SUPER"
local disintegrateClose = "python3 \"$HOME/.config/hypr/scripts/close_disintegrate.py\""

-- External commands
local launchPrefix = "uwsm app -- "
local jugoo = "${XDG_BIN_HOME:-$HOME/.local/bin}/jugoo"

-- Mark windows launched by bind for float_place (opt-in).
local launchRules = { tag = "+autoplace" }

local function launch(cmd)
    return hl.dsp.exec_cmd(cmd, launchRules)
end

-- Commands sent to the running Jugoo instance (Gio.Application primary).
-- Prefer: jugoo action <name>   (see: jugoo action list)
-- Legacy --toggle-* flags still work and map to the same actions.
local function jugoo_cmd(args)
    return hl.dsp.exec_cmd("/bin/sh -c '\"" .. jugoo .. "\" " .. args .. "'")
end


---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Window manipulation
hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
hl.bind(mainMod .. " + Q",           hl.dsp.exec_cmd(disintegrateClose))
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))

-- Maximize / fullscreen: layout_aware=false (hermanas debajo, restore limpio).
hl.bind(mainMod .. " + D", function()
    toggle_maximize_consume()
end)

hl.bind(mainMod .. " + F", function()
    toggle_fullscreen_consume()
end)

hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))


-- Change focus
hl.bind(mainMod .. " + Left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + Up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + Down",  hl.dsp.focus({ direction = "down" }))

hl.bind("ALT + Tab",         hl.dsp.window.cycle_next())
-- No Jugoo window-switcher: keep a Hyprland cycle on Super+Tab (same family as ALT+Tab).
hl.bind(
    mainMod .. " + Tab",
    hl.dsp.exec_cmd("qs ipc -c overview call overview toggle")
)


-- Move active window around workspaces & monitors
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "d" }))

hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ monitor = MONITOR1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ monitor = MONITOR2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ monitor = MONITOR3 }))

hl.bind(mainMod .. " + SHIFT + mouse_up",   hl.dsp.window.move({ monitor = "-1" }))
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.window.move({ monitor = "+1" }))

hl.bind(
    mainMod .. " + CONTROL + SHIFT + Right",
    hl.dsp.window.move({ workspace = "m+1" })
)

hl.bind(
    mainMod .. " + CONTROL + SHIFT + Left",
    hl.dsp.window.move({ workspace = "m-1" })
)

hl.bind(
    mainMod .. " + CONTROL + SHIFT + mouse_up",
    hl.dsp.window.move({ workspace = "m-1" })
)

hl.bind(
    mainMod .. " + CONTROL + SHIFT + mouse_down",
    hl.dsp.window.move({ workspace = "m+1" })
)

for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(
        mainMod .. " + SHIFT + CONTROL + " .. key,
        hl.dsp.window.move({ workspace = "m~" .. i })
    )
end


-- Move & Resize with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())


------------------
---- LAUNCHER ----
------------------

hl.bind(mainMod .. " + Return", launch(launchPrefix .. TERMINAL))
hl.bind(mainMod .. " + E",      launch(launchPrefix .. FILE_MANAGER))
hl.bind(mainMod .. " + T",      launch(launchPrefix .. EDITOR))
hl.bind(mainMod .. " + C",      launch(launchPrefix .. CALCULATOR))
hl.bind(mainMod .. " + k",      launch(launchPrefix .. CAMARA))
hl.bind(mainMod .. " + o",      launch(launchPrefix .. OBSIDIAN))
hl.bind(mainMod .. " + W",      launch(launchPrefix .. BROWSER))

-- Jugoo (running instance via Gio.Application — does not spawn a second shell)
hl.bind(mainMod .. " + Space",  jugoo_cmd("action launcher"))
hl.bind(mainMod .. " + period", jugoo_cmd("action emoji"))
hl.bind(mainMod .. " + V",      jugoo_cmd("action clipboard"))
-- Settings also opens from Search; global bind kept for muscle memory.
hl.bind(mainMod .. " + Z",      jugoo_cmd("action settings"))
hl.bind(mainMod .. " + X",      jugoo_cmd("action control-center"))
hl.bind(mainMod .. " + A",      jugoo_cmd("action notifications"))
hl.bind(mainMod .. " + ALT + C", jugoo_cmd("action session"))

-- Session lock
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- Poweroff
hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("systemctl poweroff"))


---------------------------
---- HARDWARE CONTROLS ----
---------------------------

-- Audio
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true }
)

hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true }
)

-- Audio rápido con mainMod
hl.bind(
    mainMod .. " + XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"),
    { locked = true, repeating = true }
)

hl.bind(
    mainMod .. " + XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"),
    { locked = true, repeating = true }
)

-- Intercambia entre salidas de audio (audífonos / parlantes)
hl.bind(
    mainMod .. " + M",
    hl.dsp.exec_cmd("~/.local/bin/audio-toggle")
)


-- Media
hl.bind(
    mainMod .. " + F9",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true }
)

hl.bind(
    mainMod .. " + F10",
    jugoo_cmd("action playStopMusic"),
    { locked = true }
)

hl.bind(
    mainMod .. " + F11",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true }
)

-- Brightness
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl set 5%+"),
    { locked = true, repeating = true }
)

hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl set 5%-"),
    { locked = true, repeating = true }
)


-------------------
---- UTILITIES ----
-------------------

-- Screen Capture
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprpicker -a -n"))

hl.bind(
    mainMod .. " + SHIFT + C",
    hl.dsp.exec_cmd("flameshot gui")
)

hl.bind(
    mainMod .. " + SHIFT + X",
    hl.dsp.exec_cmd("~/.local/bin/ocr-wayland.sh")
)

hl.bind(
    mainMod .. " + SHIFT + P",
    hl.dsp.exec_cmd("flameshot full -p $HOME/Pictures")
)


-- Wallpaper
hl.bind(
    mainMod .. " + SHIFT + W",
    hl.dsp.exec_cmd("waywallen"),
    { locked = true }
)


-------------------------------
---- WORKSPACES & MONITORS ----
-------------------------------

-- Focus on workspace number (Super + <num>)
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i })
    )
end


-- Focus on workspace number
-- Absolute
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(
        mainMod .. " + TAB + " .. key,
        hl.dsp.focus({ workspace = i })
    )
end


-- Relative
for i = 1, NUM_WPM do
    local key = i % 10
    hl.bind(
        mainMod .. " + CONTROL + " .. key,
        hl.dsp.focus({ workspace = "m~" .. i })
    )
end


-- Move to adjacent workspaces and next empty on a given monitor
hl.bind(
    mainMod .. " + CONTROL + Right",
    hl.dsp.focus({ workspace = "m+1" })
)

hl.bind(
    mainMod .. " + CONTROL + Left",
    hl.dsp.focus({ workspace = "m-1" })
)

hl.bind(
    mainMod .. " + CONTROL + Down",
    hl.dsp.focus({ workspace = "emptym" })
)


-- Scroll through existing workspaces & monitors
hl.bind(
    mainMod .. " + mouse_down",
    hl.dsp.focus({ workspace = "m+1" })
)

hl.bind(
    mainMod .. " + mouse_up",
    hl.dsp.focus({ workspace = "m-1" })
)

hl.bind(
    mainMod .. " + CONTROL + mouse_up",
    hl.dsp.focus({ workspace = "m+1" })
)

hl.bind(
    mainMod .. " + CONTROL + mouse_down",
    hl.dsp.focus({ workspace = "m-1" })
)


-- Special workspace (minimizados / scratchpad)
hl.bind(
    mainMod .. " + SHIFT + SPACE",
    hl.dsp.exec_cmd(
        "/home/carlosjgo/.config/hypr/scripts/toggle_minimizados.py"
    )
)

hl.bind(
    mainMod .. " + SHIFT + CONTROL + Space",
    hl.dsp.exec_cmd(
        "/home/carlosjgo/.config/hypr/scripts/toggle_minimizados.py restore-all"
    )
)

hl.bind(
    mainMod .. " + ALT + CONTROL + Space",
    hl.dsp.workspace.toggle_special("minimizados")
)


-- Special workspace (scratchpad)
hl.bind(
    mainMod .. " + SHIFT + S",
    hl.dsp.window.move({ workspace = "special" })
)

hl.bind(
    mainMod .. " + S",
    hl.dsp.workspace.toggle_special()
)


-- Pasar todas las ventanas de un workspace a otro
hl.bind(
    mainMod .. " + CONTROL + SHIFT + Up",
    hl.dsp.exec_cmd(
        "python ~/.config/hypr/scripts/move_workspace_contents.py +1 " .. NUM_WPM
    )
)

hl.bind(
    mainMod .. " + CONTROL + SHIFT + Down",
    hl.dsp.exec_cmd(
        "python ~/.config/hypr/scripts/move_workspace_contents.py -1 " .. NUM_WPM
    )
)