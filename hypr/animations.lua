-- =============================================================================
--  animations.lua — Sharp & Settled
--  Philosophy: fast entries with weight, instant exits, spatial workspaces.
--  No springs — pure bezier for precision over organicness.
-- =============================================================================

hl.config({
    animations = {
        enabled = true,
    },
})

-- -----------------------------------------------------------------------------
-- Bezier Curves
--
--   snap  — easeOutExpo shape: rockets out of the start, stops precisely.
--           Used for most entrances and transitions.
--
--   fall  — easeOutCirc shape: starts with momentum (feels like gravity),
--           decelerates into the final position. Gives windows "weight".
--
--   linear — even pacing, used for exits so they don't ease-in awkwardly.
-- -----------------------------------------------------------------------------

hl.curve("snap",   { type = "bezier", points = { {0.16, 1},   {0.3, 1}  } })
hl.curve("fall",   { type = "bezier", points = { {0, 0.55},   {0.45, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0},      {1, 1}    } })

-- -----------------------------------------------------------------------------
-- Animations
-- -----------------------------------------------------------------------------

-- Global fallback — anything not explicitly set inherits this.
hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "snap" })

-- Border (border_size = 0, so this is dormant — kept for completeness).
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "snap" })

-- Windows — parent sets the curve with weight; children override for in/out.
--   "fall" gives the window a sense of dropping into its tile.
hl.animation({ leaf = "windows",    enabled = true, speed = 5,   bezier = "snap"   })
--   popin 78%: 22% of scale travel — dramatic enough to register, the snap
--   curve makes it feel like it punches open rather than easing in.
--   Slower speed so the curve has room to be visible.
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 2.5, bezier = "snap",   style = "gnomed" })
--   Exits shrink slightly and vanish. Fast linear — no easing delay.
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.2, bezier = "linear", style = "popin 88%" })

-- Fade — governs opacity transitions (focus changes, inactive_opacity, etc.)
hl.animation({ leaf = "fade",    enabled = true, speed = 3,   bezier = "snap"   })
hl.animation({ leaf = "fadeIn",  enabled = true, speed = 2.5, bezier = "snap"   })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "linear" })

-- Layers — rofi and quickshell live here.
--   popin instead of fade: rofi materializes from a smaller size rather than
--   just brightening. More distinct, still sharp.
hl.animation({ leaf = "layers",        enabled = true, speed = 3,   bezier = "snap"   })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 2.5, bezier = "snap",   style = "popin 82%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1,   bezier = "linear", style = "popin 90%" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2,   bezier = "snap"   })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1,   bezier = "linear" })

-- Workspaces — slide instead of fade: makes the spatial layout tangible.
--   The snap curve keeps it snappy rather than drifting.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3.5, bezier = "snap", style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.5, bezier = "snap", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "snap", style = "slide" })

-- ZoomFactor — cursor zoom via gesture.
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5, bezier = "snap" })

-- New in 0.56: shadow/glow gradient angle (disabled — not using gradient shadow).
hl.animation({ leaf = "shadowangle", enabled = false, speed = 5, bezier = "linear", style = "once" })
hl.animation({ leaf = "glowangle",   enabled = false, speed = 5, bezier = "linear", style = "once" })
