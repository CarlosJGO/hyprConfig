return function(ctx)
    local hl = ctx.hl
    local mainMod = ctx.mainMod
    local MUSIC = ctx.MUSIC

    -------------------
    ---- UTILITIES ----
    -------------------

    -- Close only Unity's 20x20 floating XWayland windows.
    hl.bind(mainMod .. " + minus", function()
        for _, window in ipairs(hl.get_windows()) do
            if window.mapped and window.floating and window.xwayland
                and window.class == window.title
                and window.class and window.class:match("^Unity%-%d")
                and window.size and window.size.x == 20 and window.size.y == 20
                and window.address and window.address:match("^0x[0-9a-fA-F]+$")
            then
                hl.dispatch(hl.dsp.window.close({ window = "address:" .. window.address }))
            end
        end
    end)

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

    -- Focus Strawberry's existing window, or launch the music player.
    hl.bind(
        mainMod .. " + SHIFT + Z",
        function()
            for _, window in ipairs(hl.get_windows()) do
                if window.mapped and window.address
                    and (window.class == "strawberry"
                        or window.class == "org.strawberrymusicplayer.strawberry")
                then
                    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
                    return
                end
            end
            hl.dispatch(hl.dsp.exec_cmd(MUSIC))
        end,
        { locked = true }
    )

    hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("busctl --user call org.waywallen.waywallen.Daemon /org/waywallen/waywallen/Daemon org.waywallen.waywallen.Daemon1 Next"))
end