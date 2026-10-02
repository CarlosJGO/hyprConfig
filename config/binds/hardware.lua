return function(ctx)
    local hl = ctx.hl
    local mainMod = ctx.mainMod
    local ant = ctx.ant
    local play = ctx.play
    local sgt = ctx.sgt
    local jugoo_cmd = ctx.jugoo_cmd

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
        mainMod .. " + " .. ant,
        hl.dsp.exec_cmd("playerctl previous"),
        { locked = true }
    )

    hl.bind(
        mainMod .. " + " .. play,
        jugoo_cmd("action playStopMusic"),
        { locked = true }
    )

    hl.bind(
        mainMod .. " + SHIFT + F4",
        jugoo_cmd("action media"),
        { locked = true }
    )

    hl.bind(
        mainMod .. " + " .. sgt,
        hl.dsp.exec_cmd("playerctl next"),
        { locked = true }
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. ant,
        jugoo_cmd("action musicVolumeDown"),
        { locked = true, repeating = true }
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. sgt,
        jugoo_cmd("action musicVolumeUp"),
        { locked = true, repeating = true }
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

    -------- Mute/Desmute Discord
    hl.bind(
        mainMod .. " + CONTROL + M",
        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        { locked = true }
    )
end