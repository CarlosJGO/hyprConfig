-- Managed by Jugoo acomodador.py. Prefer editing the copy under packaging/hyprland/.
-- Window / layer rules for com.jugoo.Shell surfaces (float popups, no focus fights).

-- Generic Jugoo floating surfaces positioned by the shell.
-- Exclude "Jugoo Qt Center" (^Jugoo [^Q]): that rule's no_focus/suppress_event
-- would stick across merges and block reopen after hide (RE2 has no lookahead).
hl.window_rule({
    name = "shell-popups",
    match = { title = "^Jugoo [^Q]" },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = true,
    no_initial_focus = true,
    focus_on_activate = false,
    suppress_event = "activate activatefocus",
})

hl.window_rule({
    name = "NO-FOCUS-SHELL-NOTIFICATIONS",
    match = {
        class = "^com\\.jugoo\\.Shell$",
        title = "^Jugoo Notification Toast",
    },
    no_focus = true,
    no_initial_focus = true,
    focus_on_activate = false,
    suppress_event = "activate activatefocus",
})

-- Strawberry is the dedicated music player; always keep it on the music workspace.
hl.window_rule({
    name = "MUSICA-STRAWBERRY",
    match = {
        class = "^strawberry$",
    },
    workspace = "name:Musica",
})

hl.window_rule({
    name = "MUSICA-STRAWBERRY-CLASS",
    match = {
        class = "^org\\.strawberrymusicplayer\\.strawberry$",
    },
    workspace = "name:Musica",
})

hl.window_rule({
    name = "MUSICA-YOUTUBE-MUSIC",
    match = {
        class = "^zen$",
        title = ".*YouTube Music.*",
    },
    workspace = "name:Musica",
})

-- Grouped-notifications card: kept under the notifications popup. A border or
-- shadow would show around the popup while the card rests behind it. No
-- animation by default (mapping and sinking it behind the popup are instant);
-- Jugoo lifts no_anim per move so Hyprland slides it out and back with
-- windowsMove.
hl.window_rule({
    name = "SHELL-NOTIFICATION-DECK",
    match = {
        class = "^com\\.jugoo\\.Shell$",
        title = "^Jugoo Notification Deck$",
    },
    float = true,
    center = false,
    persistent_size = false,
    -- Focusable so the pointer (and the scroll wheel) stays on it instead of
    -- going to the window behind; it still never takes focus by itself.
    no_focus = false,
    no_initial_focus = true,
    -- Hovering it keeps keyboard focus on the popup: losing it would swap the
    -- popup's border to the inactive colours on every crossing.
    no_follow_mouse = true,
    focus_on_activate = false,
    suppress_event = "activate activatefocus",
    border_size = 0,
    no_shadow = true,
    no_anim = true,
})

local interactive = {
    { "SHELL-APP-LAUNCHER", "^Jugoo Launcher$" },
    { "SHELL-CLIPBOARD-PICKER", "^Jugoo Clipboard$" },
    { "SHELL-SETTINGS", "^Jugoo Configuraciones$" },
    { "SHELL-TASKS", "^Jugoo Tasks$" },
}

for _, entry in ipairs(interactive) do
    hl.window_rule({
        name = entry[1],
        match = { title = entry[2] },
        float = true,
        center = false,
        persistent_size = false,
        no_focus = false,
        no_initial_focus = false,
        focus_on_activate = true,
    })
end

-- Qt central menu + clipboard: floating centered cards. Never compositor-fullscreen.
-- Do NOT pin `size` here: a fixed size clipped the right rail when opening Ajustes.
-- Titles must start with "Jugoo Qt" so they stay outside shell-popups (^Jugoo [^Q]).
-- Prefix match: Qt/Wayland may append " — Jugoo Qt Center" (app display name).
-- Exact / suffix-only: do NOT use a bare "^Jugoo Qt Center" — notifications
-- titles end with " — Jugoo Qt Center" and must not inherit center=true.
local qt_cards = {
    { "SHELL-QT-CENTER", "^Jugoo Qt Center($| —)" },
    { "SHELL-QT-CLIPBOARD", "^Jugoo Qt Clipboard($| —)" },
    { "SHELL-QT-EMOJI", "^Jugoo Qt Emoji($| —)" },
}

for _, entry in ipairs(qt_cards) do
    hl.window_rule({
        name = entry[1],
        match = { title = entry[2] },
        float = true,
        center = true,
        persistent_size = false,
        fullscreen = false,
        suppress_event = "fullscreen maximize",
        no_focus = false,
        no_initial_focus = false,
        focus_on_activate = true,
        border_size = 0,
        no_shadow = true,
        no_anim = true,
    })
end

-- Qt notifications popup + side deck: anchored under the bell (not compositor-centered).
-- Hyprland matches the whole title; .* also accepts the Qt display-name suffix.
local qt_notification_cards = {
    { "SHELL-QT-NOTIFICATIONS", "^Jugoo Qt Notifications.*$" },
    { "SHELL-QT-NOTIFICATION-DECK", "^Jugoo Qt Notification Deck.*$" },
}

for _, entry in ipairs(qt_notification_cards) do
    hl.window_rule({
        name = entry[1],
        match = { title = entry[2] },
        float = true,
        center = false,
        persistent_size = false,
        fullscreen = false,
        suppress_event = "fullscreen maximize",
        no_focus = false,
        opacity = "1.0 override",
        no_initial_focus = entry[1] == "SHELL-QT-NOTIFICATION-DECK",
        no_follow_mouse = entry[1] == "SHELL-QT-NOTIFICATION-DECK",
        focus_on_activate = entry[1] ~= "SHELL-QT-NOTIFICATION-DECK",
        border_size = 0,
        no_shadow = true,
        no_anim = false,
    })
end

hl.window_rule({
    name = "SHELL-QT-NOTIFICATION-TOAST",
    match = { title = "^Jugoo Qt Notification Toast.*$" },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = true,
    no_initial_focus = true,
    no_follow_mouse = true,
    focus_on_activate = false,
    suppress_event = "activate activatefocus fullscreen maximize",
    pin = true,
    border_size = 0,
    no_shadow = true,
    no_anim = false,
})

-- Overlay animations live in GTK; suppress Hyprland layer slide.
hl.layer_rule({
    name = "jugoo-puertas-no-anim",
    match = {
        namespace = "^shell-(app-launcher|clipboard-picker|steam-games|radial-launcher)$",
    },
    no_anim = true,
})
