-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

o.bind("SUPER + E", "File manager", { launch = "strata" })

-- Middle-click on a window titlebar closes it (non-consuming: apps still get the click).
o.bind("mouse:274", "Close window from titlebar", os.getenv("HOME") .. "/.local/bin/titlebar-middle-close", { non_consuming = true })

-- >>> omacontrol bindings (generated; edit them in OmaControl)
hl.unbind("ALT + P")
o.bind("ALT + P", "Screenshot", "omarchy capture screenshot region")
-- <<< omacontrol bindings

-- fathom: begin
do
  local fathom = os.getenv("HOME") .. "/.config/omarchy/plugins/io.github.mtolhuys.fathom/hypr/fathom.lua"
  local file = io.open(fathom, "r")
  if file then
    file:close()
    pcall(dofile, fathom)
  end
end
-- fathom: end

-- Brightness keys: software-dim HDMI-A-1 (Samsung TV, no DDC/CI); other monitors use Omarchy's default.
do
  local b = os.getenv("HOME") .. "/.local/bin/brightness-display"
  local opts = { locked = true, repeating = true }
  o.rebind("XF86MonBrightnessUp", "Brightness up", b .. " +5%", opts)
  o.rebind("XF86MonBrightnessDown", "Brightness down", b .. " 5%-", opts)
  o.rebind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", b .. " 100%", opts)
  o.rebind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", b .. " 1%", opts)
  o.rebind("ALT + XF86MonBrightnessUp", "Brightness up precise", b .. " +1%", opts)
  o.rebind("ALT + XF86MonBrightnessDown", "Brightness down precise", b .. " 1%-", opts)
end

-- Ctrl+Alt+Plus / Ctrl+Alt+Minus: brightness up/down on the focused monitor (TV gets software dimming).
do
  local b = os.getenv("HOME") .. "/.local/bin/brightness-display"
  local opts = { repeating = true }
  o.bind("CTRL + ALT + plus", "Brightness up", b .. " +5%", opts)
  o.bind("CTRL + ALT + KP_Add", "Brightness up", b .. " +5%", opts)
  o.bind("CTRL + ALT + minus", "Brightness down", b .. " 5%-", opts)
  o.bind("CTRL + ALT + KP_Subtract", "Brightness down", b .. " 5%-", opts)
end

-- kai is the dock, so the app launcher is kai's grid rather than the Omarchy dock's.
o.rebind("SUPER + ALT + SPACE", "Apps", "kai apps")

-- SUPER+Space: app search, type straight away (no clicking "Apps" first).
-- Alt+Space: the Omarchy menu (it used to be on SUPER+Space).
o.rebind("SUPER + SPACE", "Search apps", { menu = "apps" })
o.bind("ALT + SPACE", "Omarchy menu", { menu = "root" })

-- Samsung TV input (tv-remote, ~/.config/tv-remote.conf)
o.bind("CTRL + ALT + X", "TV: switch to Xbox", os.getenv("HOME") .. "/.local/bin/tv-remote xbox")
o.bind("CTRL + ALT + P", "TV: switch back to PC", os.getenv("HOME") .. "/.local/bin/tv-remote pc")
