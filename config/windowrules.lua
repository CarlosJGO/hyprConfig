-- Window rules wiki https://wiki.hypr.land/Configuring/Basics/Window-Rules/

hl.window_rule({
    name = "wobbly-windows",
    match = { class = "negative:^com\\.jugoo\\.Shell$" },
    tag = "+shader_move:/home/carlosjgo/.config/hypr/shaders/wobble.glsl@0.6",
})

hl.window_rule({
    name = "wobbly-windows-resize",
    match = { class = "negative:^com\\.jugoo\\.Shell$" },
    tag = "+shader_resize:/home/carlosjgo/.config/hypr/shaders/wobble.glsl@0.6",
})

-- Jugoo popups: positioned by the shell, not Hyprland.
hl.window_rule({
    name = "shell-popups",
    match = { title = "^Jugoo " },
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

hl.window_rule({
    name = "SHELL-NOTIFICATION-GROUP",
    match = {
        class = "^com\\.jugoo\\.Shell$",
        title = "^Jugoo Notification Group$",
    },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = false,
    no_initial_focus = false,
    focus_on_activate = true,
})

hl.window_rule({
    name = "SHELL-APP-LAUNCHER",
    match = {
        title = "^Jugoo Launcher$",
    },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = false,
    no_initial_focus = false,
    focus_on_activate = true,
})

hl.window_rule({
    name = "SHELL-CLIPBOARD-PICKER",
    match = {
        title = "^Jugoo Clipboard$",
    },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = false,
    no_initial_focus = false,
    focus_on_activate = true,
})

hl.window_rule({
    name = "SHELL-EMOJI-PICKER",
    match = {
        title = "^Jugoo Emoji$",
    },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = false,
    no_initial_focus = false,
    focus_on_activate = true,
})

-- Puertas (launcher / clipboard / emoji): la animación puerta vive en GTK.
-- Sin esto, Hyprland aplica layers→slide y parece que caen desde arriba.
hl.layer_rule({
    name = "jugoo-puertas-no-anim",
    match = {
        namespace = "^shell-(app-launcher|clipboard-picker|emoji-picker)$",
    },
    no_anim = true,
})

-- Overlay de desintegración: sin anim de layer (si hubiera slide, “subiría” la captura).
hl.layer_rule({
    name = "hypr-disintegrate-passthrough",
    match = {
        namespace = "^hypr-window-disintegrate",
    },
    no_anim = true,
})

hl.window_rule({
    name = "SHELL-SETTINGS",
    match = {
        title = "^Jugoo Configuraciones$",
    },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = false,
    no_initial_focus = false,
    focus_on_activate = true,
})

hl.window_rule({
    name = "SHELL-TASKS",
    match = {
        title = "^Jugoo Tasks$",
    },
    float = true,
    center = false,
    persistent_size = false,
    no_focus = false,
    no_initial_focus = false,
    focus_on_activate = true,
})

-- Picture-in-Picture
hl.window_rule({
    match             = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
    float             = true,
    keep_aspect_ratio = true,
    size              = { "max(monitor_w, monitor_h)*0.25", "min(monitor_w, monitor_h)*0.25" },
    pin               = true,
})

-- Gaming
-- Allowlist: content=game, steam_app*/gamescope, Steam "Launching..." splash.
-- Everything else that opens on or is moved into name:gaming is ejected.
local gamingApps = "^(steam_app.*|gamescope)$"
local gamingWorkspace = "name:gaming"
local gamingWsName = "gaming"
local gamingEjectDelayMs = 250
local gamingEjectInFlight = {}

hl.window_rule({ match = { content = "game" }, workspace = gamingWorkspace })
hl.window_rule({ match = { xdg_tag = "^(.*game.*)$" }, workspace = gamingWorkspace, fullscreen_state = 2, content = "game", sync_fullscreen = true })
hl.window_rule({ match = { class = gamingApps }, workspace = gamingWorkspace })

hl.window_rule({
    match = {
        class = "^(steam)$",
        title = "negative:^(Steam)$",
    },
    float = true,
})

hl.window_rule({ match = { class = "^(steam)$", title = "^(Launching\\.{3})$" }, float = true, center = true, workspace = gamingWorkspace })
hl.window_rule({
    match = {
        class         = gamingApps,
        title         = "^(.+)$",
        initial_title = "negative:^(.*\\\\home\\\\.*)$",
    },
    content          = "game",
    decorate         = false,
    fullscreen_state = 2,
    size             = { "monitor_w", "monitor_h" },
    sync_fullscreen  = true,
})
hl.window_rule({
    match = {
        class         = "^(steam_app.*)$",
        initial_title = "^$",
    },
    center           = true,
    float            = true,
    fullscreen       = false,
    fullscreen_state = 0,
    workspace        = gamingWorkspace,
})

local function on_gaming_workspace(window)
    local ws = window and window.workspace
    return ws and ws.name == gamingWsName
end

local function gaming_allowed(window)
    if not window then
        return false
    end

    local content = window.content_type or window.content
    if content == "game" then
        return true
    end

    local class = window.class or ""
    if class:match("^steam_app") or class == "gamescope" then
        return true
    end

    -- Keep the Steam launch splash with the game during startup.
    if class == "steam" then
        local title = window.title or ""
        if title:match("^Launching") then
            return true
        end
    end

    return false
end

local function gaming_eject_destination()
    local last = hl.get_last_workspace()
    if last and last.name ~= gamingWsName and not last.special then
        return last.id
    end
    return 1
end

local function eject_from_gaming(window)
    if not window or not window.address or not window.mapped then
        return
    end
    if not on_gaming_workspace(window) or gaming_allowed(window) then
        return
    end
    if gamingEjectInFlight[window.address] then
        return
    end

    gamingEjectInFlight[window.address] = true
    local addr = "address:" .. window.address
    hl.dispatch(hl.dsp.window.move({
        window = addr,
        workspace = gaming_eject_destination(),
        follow = false,
    }))
    hl.timer(function()
        gamingEjectInFlight[window.address] = nil
    end, { timeout = 400, type = "oneshot" })
end

local function schedule_gaming_eject(window)
    if not window or not window.address then
        return
    end
    local addr = window.address
    hl.timer(function()
        local w = hl.get_window("address:" .. addr)
        if w then
            eject_from_gaming(w)
        end
    end, { timeout = gamingEjectDelayMs, type = "oneshot" })
end

local function sweep_gaming_workspace()
    local wins = hl.get_workspace_windows(gamingWorkspace) or {}
    for _, w in ipairs(wins) do
        eject_from_gaming(w)
    end
end

-- Open: delay so class/content can settle (steam_app often starts empty).
hl.on("window.open", schedule_gaming_eject)
-- Manual / rule moves onto gaming.
hl.on("window.move_to_workspace", function(window, workspace)
    if workspace and workspace.name == gamingWsName then
        schedule_gaming_eject(window)
    end
end)
-- Late classification (content/class/title updates while already on gaming).
hl.on("window.class", schedule_gaming_eject)
hl.on("window.title", schedule_gaming_eject)
hl.on("workspace.active", function(workspace)
    if workspace and workspace.name == gamingWsName then
        sweep_gaming_workspace()
    end
end)

-- Apps que tú lanzas y suelen flotar: tag para float_place.
-- Diálogos de Steam/Audacity/etc. NO entran aquí.
hl.window_rule({
    name = "gnome-text-editor-small",
    match = { class = "^org\\.gnome\\.TextEditor$" },
    float = true,
    persistent_size = true,
    size = { "365", "245" },
    tag = "+autoplace",
})

hl.window_rule({
    name = "gnome-snapshot-camera",
    match = { class = "^org\\.gnome\\.Snapshot$" },
    float = true,
    persistent_size = true,
    size = { "1110", "625" },
    center = true,
    tag = "+autoplace",
})

hl.window_rule({
    name = "gnome-snapshot-camera-wobble-move",
    match = { class = "^org\\.gnome\\.Snapshot$" },
    tag = "+shader_move:/home/carlosjgo/.config/hypr/shaders/wobble.glsl@2.0",
})

hl.window_rule({
    name = "gnome-snapshot-camera-wobble-resize",
    match = { class = "^org\\.gnome\\.Snapshot$" },
    tag = "+shader_resize:/home/carlosjgo/.config/hypr/shaders/wobble.glsl@2.0",
})

hl.window_rule({
    name = "kclock-small",
    match = { class = "^org\\.kde\\.kclock$" },
    float = true,
    persistent_size = true,
    size = { "300", "301" },
    tag = "+autoplace",
})


-- Unity modal dialogs
hl.window_rule({
    name = "unity-modal-dialogs",
    match = {
        class = "^Unity$",
        title = "^Unity$",
        xwayland = true,
    },
    float = true,
    center = false,
    move = {
        "max(20, min(cursor_x - (window_w * 0.50), monitor_w - window_w - 20))",
               "max(20, min(cursor_y - 50, monitor_h - window_h - 20))",
    },
})

hl.window_rule({ match = { class = "^(.*\\.exe)$", float = true }, monitor = PRIMARY_MONITOR, center = true, fullscreen_state = 0 })
hl.window_rule({ match = { class = "^(.*[Ll]auncher.*)$" }, float = true, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(vesktop|discord)$" }, monitor = PRIMARY_MONITOR })
hl.window_rule({ match = { class = "^(.*[Cc]alc.*)$" }, float = true, size = { "max(monitor_w, monitor_h)*0.17", "min(monitor_w, monitor_h)*0.43" }, tag = "+autoplace" })
hl.window_rule({ match = { class = "^(org\\.kde\\.keditfiletype)$" }, float = true })
hl.window_rule({ match = { class = "^(org\\.kde\\.ark)$" }, size = { "max(monitor_w, monitor_h)*0.40", "min(monitor_w, monitor_h)*0.40" }, tag = "+autoplace" })

hl.window_rule({
    match = {
        class = "^(org\\.kde\\.dolphin)$",
        title = "negative:^(Moving.*|Create New.*|Extract.*|Compress.*|Copying.*|Progress.*|Configure.*|Properties.*|Choose\\sApplication.*)$",
    },
    float = true,
    center = true,
    size = { "max(monitor_w, monitor_h)*0.50", "min(monitor_w, monitor_h)*0.55" },
    tag = "+autoplace",
})

-- Opacity Overrides
local terminals = "^(kitty|ghostty|[Kk]onsole|Alacritty|gnome-terminal|xfce[0-9]?-terminal)$"

hl.window_rule({ match = { class = "^(firefox|zen)$" }, opacity = "1.0 override" })
-- Terminals: keep Kitty/Ghostty transparency, but let Hyprland apply a very light blur
-- behind them so the wallpaper is softened and the text remains readable.
hl.window_rule({ match = { class = terminals }, opacity = "1.0 override" })
hl.window_rule({ match = { class = "^(mpv|org.kde.haruna|.*plex.*|org\\.kde\\.gwenview|.*vlc.*)$" }, opacity = "1.0 override" })

-- Float Utility Windows (las que sueles abrir tú)
local floatApps = {
    { class = "^(kvantummanager|qt[56]ct|nwg-look)$" },
    { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-applet|nm-connection-editor)$" },
    { title = "^(Winetricks.*|Protontricks.*)$" },
}
for _, m in ipairs(floatApps) do
    hl.window_rule({ match = m, float = true, tag = "+autoplace" })
end

-- Float Common Modals (apps hijas: NO autoplace)
local modalMatches = {
    { title = "^(Open|Authentication Required|Add Folder to Workspace|Choose Files|Save As|Confirm to replace files|File Operation Progress)$" },
    { initial_title = "^(Open File)$" },
    { class = "^([Xx]dg-desktop-portal-gtk)$" },
    { title = "^(File Upload|Choose wallpaper|Library)(.*)$" },
    { class = "^(.*dialog.*)$" },
    { title = "^(.*dialog.*)$" },
    { class = "^(hyprland-share-picker)$"},
}
for _, m in ipairs(modalMatches) do hl.window_rule({ match = m, float = true }) end

-- Ignore maximize requests from all apps. You'll probably like this.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Special workspace backgrounds (scripts/special_backgrounds.py) below desktop widgets
hl.layer_rule({ match = { namespace = "hypr-special-bg" }, order = -1 })
