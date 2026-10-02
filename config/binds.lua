local mainMod = "SUPER"
local jugoo = "${XDG_BIN_HOME:-$HOME/.local/bin}/jugoo"

local function jugoo_action(name)
    return hl.dsp.exec_cmd("gapplication action com.jugoo.Shell " .. name)
end

local function jugoo_cmd(args)
    return hl.dsp.exec_cmd("/bin/sh -c '\"" .. jugoo .. "\" " .. args .. "'")
end

local context = {
    hl = hl,
    mainMod = mainMod,
    jugoo_action = jugoo_action,
    jugoo_cmd = jugoo_cmd,
    MONITOR1 = MONITOR1,
    MONITOR2 = MONITOR2,
    MONITOR3 = MONITOR3,
    NUM_WPM = NUM_WPM,
    TERMINAL = TERMINAL,
    FILE_MANAGER = FILE_MANAGER,
    EDITOR = EDITOR,
    CALCULATOR = CALCULATOR,
    CAMARA = CAMARA,
    OBSIDIAN = OBSIDIAN,
    BROWSER = BROWSER,
    CHATGPT = CHATGPT,
    whats = whats,
    IDE = IDE,
    MUSIC = MUSIC,
    ant = ant,
    play = play,
    sgt = sgt,
    toggle_maximize_consume = toggle_maximize_consume,
    toggle_fullscreen_consume = toggle_fullscreen_consume,
}

require("config.binds.window")(context)
require("config.binds.launcher")(context)
require("config.binds.hardware")(context)
require("config.binds.utilities")(context)
require("config.binds.workspaces")(context)