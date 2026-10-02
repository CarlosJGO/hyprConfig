return function(ctx)
    local hl = ctx.hl
    local mainMod = ctx.mainMod
    local NUM_WPM = ctx.NUM_WPM

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
end