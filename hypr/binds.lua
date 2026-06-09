-- =============================================================================
--  binds.lua — keybindings
-- =============================================================================

local mainMod     = "SUPER"
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"

-- reloads hyprland
hl.bind(mainMod .. " + backslash", hl.dsp.exec_cmd("hyprctl reload"))

-----------------------------
---- LAUNCH -----------------
-----------------------------

hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd(menu))

-- opens rofimoji
hl.bind(mainMod .. " + period",  hl.dsp.exec_cmd("~/.config/rofi/emoji-picker.sh"))

-- uses tint to choose a random wallpaper
hl.bind(mainMod .. " + W",  hl.dsp.exec_cmd("tint random DP-3,HDMI-A-1 grow"))

-- hypralt
hl.bind("ALT + TAB",  hl.dsp.exec_cmd("hypralt"))

-----------------------------
---- WINDOW MANAGEMENT ------
-----------------------------

-- Kill focused window
hl.bind(mainMod .. " + tab", hl.dsp.window.close())

-- Float toggle
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))

-- Fullscreen (true fullscreen, no topbar)
hl.bind(mainMod .. " + ALT + F", hl.dsp.window.fullscreen())

-- Exit
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
))


-----------------------------
---- FOCUS (arrows) ---------
-----------------------------

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))


-----------------------------
---- MOVE WINDOW (arrows) ---
-----------------------------

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))


-----------------------------
---- MOUSE ------------------
-----------------------------

-- mainMod + LMB drag = move window
-- mainMod + RMB drag = resize window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-----------------------------
---- TOOLS ------------------
-----------------------------

-- Main screenshot bind: Freezes screen, lets you select area, saves, copies, and opens in Swappy
hl.bind("Print", hl.dsp.exec_cmd("bash -c 'grimblast --freeze copysave area ~/Pictures/Screenshots/screenshot.png && swappy -f ~/Pictures/Screenshots/screenshot.png'"))

-- The Panic Button: Instantly kills all screenshot processes if the screen gets stuck
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("killall -9 grimblast swappy slurp hyprpicker grim"))

-----------------------------
---- WORKSPACES -------------
-----------------------------

-- Switch workspaces (1-9 and 0 → 10)
-- Move active window to workspace
for i = 1, 10 do
    local key = i % 10  -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end


-----------------------------
---- MEDIA KEYS -------------
-----------------------------

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),    { locked = true })
