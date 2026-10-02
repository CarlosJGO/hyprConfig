return function(ctx)
    local hl = ctx.hl
    local mainMod = ctx.mainMod
    local MUSIC = ctx.MUSIC

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

    -- Strawberry (music player)
    hl.bind(
        mainMod .. " + SHIFT + Z",
        hl.dsp.exec_cmd(MUSIC),
        { locked = true }
    )

    hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("busctl --user call org.waywallen.waywallen.Daemon /org/waywallen/waywallen/Daemon org.waywallen.waywallen.Daemon1 Next"))
end