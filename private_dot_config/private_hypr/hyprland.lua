-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false
--
-- Disable Omarchy's default touchpad gestures. Add your own in hypr/input.lua.
-- omarchy_default_gestures = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.snap") -- Windows-style snapping (drag to edges, SUPER+arrows)
require("hypr.desktop") -- SUPER+D show desktop
require("hypr.no-workspaces") -- one desktop per screen, workspace keys off
require("hypr.looknfeel")
require("hypr.autostart")

-- Load settings written by OmaControl (omacontrol:managed).
-- It belongs above the toggles below: those turn the laptop
-- display off with a monitor rule, and a rule of ours read
-- afterwards would replace it and put the display back on.
require("hypr.omacontrol")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Load settings written by OmaSettings (omasettings:managed).
require("hypr.omasettings")

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
