-- Look and feel configuration

local function random_color()
    return string.format(
        "rgba(%02x%02x%02xff)",
        math.random(0, 255),
        math.random(0, 255),
        math.random(0, 255)
    )
end

hl.config({

    general = {

        gaps_in = 3,

        gaps_out = 8,

        border_size = 2,

        extend_border_grab_area = 10,

        resize_on_border = true,

        col = {

            active_border = {

                colors = { random_color() },

                angle = 45,

            },

            inactive_border = CACHYGRAY,

        },

    },

    group = {

        col = {

            border_active = CACHYLBLUE,

            border_inactive = CACHYGRAY,

            border_locked_active = CACHYDBLUE,

            border_locked_inactive = CACHYGRAY,

        },

        groupbar = {

            col = {

                active = CACHYLGREEN,

                inactive = CACHYGRAY,

                locked_active = CACHYDBLUE,

                locked_inactive = CACHYGRAY,

            },

        },

    },

    decoration = {

        dim_special = 0.85,

        rounding = 0,

        active_opacity = 0.95,

        inactive_opacity = 0.85,

        fullscreen_opacity = 1,

    },

})
