return function(ctx)
    local hl = ctx.hl
    local mainMod = ctx.mainMod
    local launchPrefix = "uwsm app -- "
    local launchRules = { tag = "+autoplace" }
    local jugoo_action = ctx.jugoo_action
    local jugoo_cmd = ctx.jugoo_cmd
    local TERMINAL = ctx.TERMINAL
    local FILE_MANAGER = ctx.FILE_MANAGER
    local EDITOR = ctx.EDITOR
    local CALCULATOR = ctx.CALCULATOR
    local CAMARA = ctx.CAMARA
    local OBSIDIAN = ctx.OBSIDIAN
    local BROWSER = ctx.BROWSER
    local CHATGPT = ctx.CHATGPT
    local whats = ctx.whats
    local IDE = ctx.IDE

    local function launch(cmd)
        return hl.dsp.exec_cmd(cmd, launchRules)
    end

    ------------------
    ---- LAUNCHER ----
    ------------------

    hl.bind("mouse:272", jugoo_action("dismiss-popups-outside"), { non_consuming = true })
    hl.bind("mouse:273", jugoo_action("dismiss-popups-outside"), { non_consuming = true })

    hl.bind(mainMod .. " + Return", jugoo_cmd("action ask"))

    -- Double-tap Super → terminal. Needs "SUPER + SUPER_L/R" (not bare SUPER_L):
    -- on release the SUPER modmask is still set, so modmask:0 never matches.
    local doubleSuperTimeoutMs = 400
    local doubleSuperPending = false

    local function onSuperRelease()
        if doubleSuperPending then
            doubleSuperPending = false
            hl.dispatch(launch(launchPrefix .. TERMINAL))
            return
        end

        doubleSuperPending = true
        hl.timer(function()
            doubleSuperPending = false
        end, { timeout = doubleSuperTimeoutMs, type = "oneshot" })
    end

    -------esto es para abrir la terminal con super + super, si se presiona dos veces el super se abre la terminal
    hl.bind(mainMod .. " + SUPER_L", onSuperRelease, { release = true, non_consuming = true })
    hl.bind(mainMod .. " + SUPER_R", onSuperRelease, { release = true, non_consuming = true })

    hl.bind(mainMod .. " + E",      launch(launchPrefix .. FILE_MANAGER))
    hl.bind(mainMod .. " + T",      launch(launchPrefix .. EDITOR))
    hl.bind(mainMod .. " + C",      launch(launchPrefix .. CALCULATOR))
    hl.bind(mainMod .. " + k",      launch(launchPrefix .. CAMARA))
    hl.bind(mainMod .. " + o",      launch(launchPrefix .. OBSIDIAN))
    hl.bind(mainMod .. " + W",      launch(launchPrefix .. BROWSER))
    hl.bind(mainMod .. " + CONTROL + c", launch(launchPrefix .. CHATGPT))
    hl.bind(mainMod .. " + CONTROL + w", launch(launchPrefix .. whats))
    hl.bind(mainMod .. " + ALT + w", launch(launchPrefix .. IDE))

    -- Jugoo (running instance via Gio.Application — does not spawn a second shell)
    hl.bind(mainMod .. " + Space",  jugoo_action("launcher"))
    hl.bind(mainMod .. " + period", jugoo_action("emoji"))
    hl.bind(mainMod .. " + V",      jugoo_action("clipboard"))
    -- Settings also opens from Search; global bind kept for muscle memory.
    hl.bind(mainMod .. " + Z",      jugoo_cmd("action settings"))
    hl.bind(mainMod .. " + X",      jugoo_cmd("action control-center"))
    hl.bind(mainMod .. " + A",      jugoo_cmd("action notifications"))
    hl.bind(mainMod .. " + ALT + C", jugoo_cmd("action session"))

    -- Session lock
    hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("/home/carlosjgo/.local/bin/hyprlock-random-bg"))
    -- Poweroff
    hl.bind(mainMod .. " + Delete", hl.dsp.exec_cmd("systemctl poweroff"))
end