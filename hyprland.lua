-- Hyprland Lua config, converted from hyprland.conf on 2026-10-06.
-- Backup of the legacy config: hyprland.conf.bak-2026-10-06
-- Refer to the wiki: https://wiki.hypr.land/configuring/core/
-- Autocompletion stubs: /usr/share/hypr/stubs/


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
-- Laptop (darkone): built-in 15.6" 2560x1440 at 60 Hz (240 Hz heats the Intel iGPU), scale 1.25 (2048x1152 usable)
hl.monitor({ output = "eDP-1", mode = "2560x1440@60", position = "0x0", scale = 1.25, reserved_area = { top = 38 } })
hl.monitor({ output = "",      mode = "preferred",     position = "auto", scale = 1, reserved_area = { top = 38 } })

-- Hybrid graphics (Intel Iris Xe + RTX 3070 Ti): the desktop stays on the Intel iGPU (eDP-1 is wired to it).
-- The NVIDIA GPU stays free for CUDA (ComfyUI, Kobold, Blender Cycles); OpenGL/Vulkan apps on it: prime-run <app>


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local menu        = "hyprlauncher"
local fileManager = "/usr/bin/nautilus"
-- local menu     = "wofi --show drun"
local browser     = "firefox"
local brave       = "brave --ozone-platform=wayland --enable-features=UseOzonePlatform"
local obsidian    = "obsidian"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/waybar/scripts/bar-color.sh; waybar -c ~/.config/waybar/config-darkone -s ~/.cache/waybar/style.css & swaync")   -- random bar colors (D-013)
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")

    -- Apps on their workspaces (icons in waybar: 1 browser, 2 terminal, 3 notes, 4 music)
    -- Laptop: only Obsidian at start (ws 3); no OLED care (LCD screen): no hypridle, awww, border steps
    hl.exec_cmd(obsidian, { workspace = "3 silent" })
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
----- PERMISSIONS -----
-----------------------

-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Laptop: plain dwindle (lua:centre in layouts/centre.lua is for the 32:9 G93SD, branch bigblackarch)

-- See https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in  = 5,
        -- gaps_out = 20,
        gaps_out = 8,

        border_size = 2,

        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see the Tearing page on the wiki before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Curves and animations, see https://wiki.hypr.land/configuring/core/animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "borderangle",   enabled = false })   -- static gradient
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 4,    bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 4,    bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 4,    bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,          -- no default wallpaper
        disable_hyprland_logo   = true,       -- no logo / mascot background
        background_color        = "0x1a1a1a", -- plain dark gray background (no awww on the laptop)
        mouse_move_enables_dpms = true,       -- wake the screen after a manual dpms off (F13)
        key_press_enables_dpms  = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,   -- laptop touchpad (as in the former darkone config)
        },
    },
})

-- See https://wiki.hypr.land/configuring/core/binds/gestures/
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- Example per-device config, see https://wiki.hypr.land/configuring/core/devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- See https://wiki.hypr.land/configuring/core/binds/
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + X",      hl.dsp.window.close())
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + space",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())          -- dwindle
hl.bind(mainMod .. " + R",      hl.dsp.layout("togglesplit"))    -- dwindle
-- Same keys as the lua:centre binds of bigblackarch, dwindle equivalents
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })   -- narrower
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0, relative = true }), { repeating = true })   -- wider
hl.bind(mainMod .. " + SHIFT + left",   hl.dsp.window.move({ direction = "left" }))    -- move window
hl.bind(mainMod .. " + SHIFT + right",  hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",     hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",   hl.dsp.window.move({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.layout("swapsplit"))   -- swap the two halves of the split

hl.bind(mainMod .. " + F", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(brave))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd(obsidian))

hl.bind(mainMod .. " + Z", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

hl.bind("PRINT",                hl.dsp.exec_cmd("hyprshot -m window -o ~/Images/Screenshots"))
hl.bind("CTRL + PRINT",         hl.dsp.exec_cmd("hyprshot -m region -o ~/Images/Screenshots"))
hl.bind("CTRL + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m output -o ~/Images/Screenshots"))
hl.bind("XF86Tools", hl.dsp.exec_cmd("sleep 1 && hyprctl dispatch 'hl.dsp.dpms({action = \"off\"})'"))  -- F13 (Keychron knob click): screen off after 1 s, wakes on any input

-- Move focus with mainMod + h/j/k/l (same mapping as the legacy config)
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
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

-- Single screen (G93SD, D-007): workspaces are no longer pinned to monitors.
-- Previous two-screen rules (D-002, replaced):
-- hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
-- for i = 2, 10 do
--     hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = (i == 2) })
-- end

-- Workspace 6 video setup (D-015/D-016) disabled by D-018: normal layout, players open where started,
-- Waybar not hidden (fullscreen covers it). Uncomment to restore.
-- -- Workspace 6 = video (D-015): lua:video, no gaps / border / rounding
-- hl.workspace_rule({ workspace = "6", layout = "lua:video", gaps_in = 0, gaps_out = 0, no_border = true, no_rounding = true })
-- hl.window_rule({ name = "vlc-on-workspace-6", match = { class = "^vlc$" }, workspace = "6 silent" })
-- hl.window_rule({ name = "mpv-on-workspace-6", match = { class = "^mpv$" }, workspace = "6 silent" })   -- fullscreen (mpv.conf), blurred sides (D-016)
-- -- VLC told it is fullscreen (hides its controls) but kept in its layout box; 1 s after mapping,
-- -- earlier is ignored (tested)
-- hl.on("window.open", function(w)
--     if w and w.class == "vlc" then
--         hl.exec_cmd("sleep 1; hyprctl dispatch 'hl.dsp.window.fullscreen_state({ internal = 0, client = 2, window = \"address:" .. w.address .. "\" })'")
--     end
-- end)
-- -- Waybar hidden on workspace 6, shown again elsewhere
-- hl.on("workspace.active", function(ws)
--     hl.exec_cmd((ws and ws.id == 6) and "pkill -SIGUSR1 -x waybar" or "pkill -SIGUSR2 -x waybar")
-- end)

-- QBZ: its window maps too late for exec rules, place it by class
hl.window_rule({
    name      = "qbz-on-workspace-4",
    match     = { class = "^com\\.blitzfc\\.qbz$" },
    workspace = "4 silent",
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
