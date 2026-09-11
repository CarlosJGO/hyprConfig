-- hyprfocus (Vaxry / hyprland-plugins)
-- Flash sutil al cambiar el foco.
-- Docs: https://github.com/hyprwm/hyprland-plugins/tree/main/hyprfocus
--
-- Las claves plugin:* solo existen DESPUÉS de cargar el .so (hyprpm reload).
-- No uses hl.config(plugin.hyprfocus) si el plugin no está cargado:
-- Hyprland marca "unknown config key".

hl.permission({
    binary = "/usr/(bin|local/bin)/hyprpm",
    type = "plugin",
    mode = "allow",
})

local function hyprfocus_loaded()
    for _, plugin in ipairs(hl.get_loaded_plugins() or {}) do
        local name = (plugin.name or ""):lower()
        if name == "hyprfocus" then
            return true
        end
    end
    return false
end

local function apply_hyprfocus()
    if not hyprfocus_loaded() then
        return false
    end

    hl.config({
        plugin = {
            hyprfocus = {
                enable = true,
                animate_floating = true,
                only_on_monitor_change = false,
                keyboard_focus_animation = "flash",
                mouse_focus_animation = "flash",
                fade_opacity = 0.88,
                shrink_percentage = 0.97,
                slide_height = 12,
            },
        },
    })

    hl.animation({
        leaf = "hyprfocusIn",
        enabled = true,
        speed = 1.5,
        bezier = "smoothOut",
    })

    hl.animation({
        leaf = "hyprfocusOut",
        enabled = true,
        speed = 2.5,
        bezier = "smooth",
    })

    return true
end

apply_hyprfocus()

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload -n")

    local attempts = 0
    local function try_apply()
        attempts = attempts + 1
        if apply_hyprfocus() or attempts >= 10 then
            return
        end
        hl.timer(try_apply, { timeout = 500, type = "oneshot" })
    end

    hl.timer(try_apply, { timeout = 400, type = "oneshot" })
end)
