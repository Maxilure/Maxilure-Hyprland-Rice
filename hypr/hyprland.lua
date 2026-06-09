-- =============================================================================
--  hyprland.lua — entry point
--  All settings are split across separate files in ~/.config/hypr/
-- =============================================================================

local H = os.getenv("HOME") .. "/.config/hypr/"
dofile(H .. "monitors.lua")
dofile(H .. "env.lua")
dofile(H .. "settings.lua")
dofile(H .. "animations.lua")
dofile(H .. "rules.lua")
dofile(H .. "binds.lua")
dofile(H .. "startup.lua")
