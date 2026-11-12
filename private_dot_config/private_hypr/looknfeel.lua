-- Change the default Omarchy look'n'feel.

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- >>> lacquer managed block >>>
-- Written by Lacquer. Safe to hand-edit: Lacquer re-reads this block
-- every time it opens, and only ever rewrites what's between the fences.
hl.config({
  cursor = {
    hide_on_key_press = true,
    inactive_timeout = 1,
  },

  decoration = {
    rounding_power = 1,
  },

  general = {
    border_size = 0,
    gaps_in = 0,
    gaps_out = 0,
    gaps_workspaces = 0,
    layout = "scrolling",
  },
})
-- <<< lacquer managed block <<<

-- Animated gradient window border (pink/orange, ported from the Hyper hyperBorder config).
hl.config({
  general = {
    border_size = 4,
    col = {
      active_border = { colors = { "rgba(fc1da7ff)", "rgba(fba506ff)", "rgba(fc1da7ff)", "rgba(fba506ff)" }, angle = 180 },
      inactive_border = { colors = { "rgba(fc1da7ff)", "rgba(fba506ff)" }, angle = 180 },
    },
  },
  decoration = {
    rounding = 20,
    active_opacity = 1.0,
  },
})

-- Spin the gradient continuously. speed is in tenths of a second per full
-- rotation: 1 = 0.1s (very fast), 30 = 3s, 80 = 8s.
hl.animation({ leaf = "borderangle", enabled = true, speed = 20, bezier = "linear", style = "loop" })

-- Focused windows fully opaque; unfocused keep Omarchy's 0.96 transparency.
o.transparent_window({ tag = "terminal" }, "1.0 0.96")
o.transparent_window("(omawrite|1[pP]assword|com\\.onepassword\\.OnePassword|org\\.gnome\\.Nautilus)", "1.0 0.96")
o.transparent_window({ tag = "transparent" }, "1.0 0.96")
