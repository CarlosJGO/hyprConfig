return function(ctx)
    local hl = ctx.hl
    local mainMod = ctx.mainMod
    local MONITOR1 = ctx.MONITOR1
    local MONITOR2 = ctx.MONITOR2
    local MONITOR3 = ctx.MONITOR3
    local NUM_WPM = ctx.NUM_WPM
    local toggle_maximize_consume = ctx.toggle_maximize_consume
    local toggle_fullscreen_consume = ctx.toggle_fullscreen_consume
    local disintegrateClose = "python3 \"$HOME/.config/hypr/scripts/close_disintegrate.py\""

    ---------------------------
    ---- WINDOW MANAGEMENT ----
    ---------------------------

    -- Window manipulation
    hl.bind(mainMod .. " + Escape",      hl.dsp.exec_cmd("hyprctl kill"))
    hl.bind(mainMod .. " + Q",           hl.dsp.exec_cmd(disintegrateClose))
    hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))

    -- Incremental resize
    hl.bind(mainMod .. " + ALT + Right",
        hl.dsp.window.resize({ x = 10, y = 0, relative = true }),
        { repeating = true })

    hl.bind(mainMod .. " + ALT + Left",
        hl.dsp.window.resize({ x = -10, y = 0, relative = true }),
        { repeating = true })

    hl.bind(mainMod .. " + ALT + Down",
        hl.dsp.window.resize({ x = 0, y = 10, relative = true }),
        { repeating = true })

    hl.bind(mainMod .. " + ALT + Up",
        hl.dsp.window.resize({ x = 0, y = -10, relative = true }),
        { repeating = true })

    -------Diagonal resize (ALT + Up/Down + Left/Right)
    hl.bind(mainMod .. " + ALT + Up + Right",
        hl.dsp.window.resize({ x = 10, y = -10, relative = true }),
        { repeating = true })

    hl.bind(mainMod .. " + ALT + Up + Left",
        hl.dsp.window.resize({ x = -10, y = -10, relative = true }),
        { repeating = true })

    hl.bind(mainMod .. " + ALT + Down + Right",
        hl.dsp.window.resize({ x = 10, y = 10, relative = true }),
        { repeating = true })

    hl.bind(mainMod .. " + ALT + Down + Left",
        hl.dsp.window.resize({ x = -10, y = 10, relative = true }),
        { repeating = true })


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

    -- Carry window to another WS with the same horizontal slide as focus-only switches.
    -- Native movetoworkspace relocates the window before the workspace anim, so it teleports.
    -- Float+pin keeps it fixed on screen while workspaces slide; then we silent-move + restore.
    local moveWsSlideMs = 450 -- workspaces speed 4 (=400ms) + margin
    local moveWsSlideBusy = false

    local function move_window_follow_slide(workspace)
        if moveWsSlideBusy then
            return
        end

        local win = hl.get_active_window()
        if not win then
            return
        end

        local addr = "address:" .. win.address
        local was_floating = win.floating
        local was_pinned = win.pinned

        if win.fullscreen ~= 0 then
            hl.dispatch(hl.dsp.window.move({ workspace = workspace, follow = true, window = addr }))
            return
        end

        moveWsSlideBusy = true

        if not was_floating then
            hl.dispatch(hl.dsp.window.float({ action = "set", window = addr }))
        end
        if not was_pinned then
            hl.dispatch(hl.dsp.window.pin({ action = "set", window = addr }))
        end

        hl.dispatch(hl.dsp.focus({ workspace = workspace }))

        hl.timer(function()
            local cur = hl.get_active_workspace()
            if cur then
                hl.dispatch(hl.dsp.window.move({
                    window = addr,
                    workspace = cur.id,
                    follow = false,
                }))
            end

            if not was_pinned then
                hl.dispatch(hl.dsp.window.pin({ action = "unset", window = addr }))
            end
            if not was_floating then
                hl.dispatch(hl.dsp.window.float({ action = "unset", window = addr }))
            end

            hl.dispatch(hl.dsp.focus({ window = addr }))
            moveWsSlideBusy = false
        end, { timeout = moveWsSlideMs, type = "oneshot" })
    end

    hl.bind(mainMod .. " + CONTROL + SHIFT + Right", function()
        move_window_follow_slide("m+1")
    end)

    hl.bind(mainMod .. " + CONTROL + SHIFT + Left", function()
        move_window_follow_slide("m-1")
    end)

    hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_up", function()
        move_window_follow_slide("m-1")
    end)

    hl.bind(mainMod .. " + CONTROL + SHIFT + mouse_down", function()
        move_window_follow_slide("m+1")
    end)

    for i = 1, NUM_WPM do
        local key = i % 10
        local ws = "m~" .. i
        hl.bind(mainMod .. " + SHIFT + CONTROL + " .. key, function()
            move_window_follow_slide(ws)
        end)
    end


    -- Move & Resize with mouse
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())
end