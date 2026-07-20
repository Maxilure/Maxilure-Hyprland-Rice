-- =============================================================================
--  rules.lua — window rules and layer rules
-- =============================================================================

-- Ignore maximize requests from all apps
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

hl.layer_rule({
    name  = "blur-rofi",
    match = { namespace = "^rofi$" },

    blur        = true, 
})

hl.layer_rule({
    name  = "blur-quickshell",
    match = { namespace = "^quickshell$" },

    blur         = true,
    blur_popups  = true,
    -- Blur follows the surface rect, not the drawn pixels; skip anything more
    -- transparent than the panel background (C.base is 0.90 alpha) so fully
    -- transparent regions — the toast strip, rounded-corner outsides, the gap
    -- between bar and popup — stay unblurred.
    ignore_alpha = 0.5,
})

