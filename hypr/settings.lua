-- =============================================================================
--  settings.lua — general, decoration, layouts, input, misc
-- =============================================================================


--------------------
---- GENERAL -------
--------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 20,

        border_size = 0,

        col = {
            active_border   = "rgba(ffffffff)",
            inactive_border = "rgba(ffffffff)",
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },
})


----------------------
---- DECORATION -------
----------------------

hl.config({
    decoration = {
        rounding       = 0,
        rounding_power = 0,

        active_opacity   = 1.0,
        inactive_opacity = 0.9,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 2,
            vibrancy = 0.1696,
        },
    },
})


--------------------
---- LAYOUTS -------
--------------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})


--------------------
---- MISC ----------
--------------------

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})


--------------------
---- INPUT ---------
--------------------

hl.config({
    input = {
        kb_layout  = "us,ara",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
