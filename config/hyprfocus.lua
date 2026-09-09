-- hyprfocus (Vaxry / hyprland-plugins)
-- Flash sutil al cambiar el foco. Independiente de las animaciones nativas.
-- Docs: https://github.com/hyprwm/hyprland-plugins/tree/main/hyprfocus

hl.config({
    plugin = {
        hyprfocus = {
            enable = true,
            animate_floating = true,
            only_on_monitor_change = false,

            -- Efecto: flash de opacidad (shrink/slide también disponibles)
            keyboard_focus_animation = "flash",
            mouse_focus_animation = "flash",

            -- Pico del flash; más cerca de 1.0 = más sutil
            -- (active_opacity del escritorio ya es ~0.95)
            fade_opacity = 0.88,

            -- Reservados por si cambias el modo (no afectan en flash)
            shrink_percentage = 0.97,
            slide_height = 12,
        },
    },
})

-- Timing del flash (hojas que registra el plugin; no sustituyen windowsIn/Out)
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
