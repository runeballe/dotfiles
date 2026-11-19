-- No workspaces (Rune): one desktop per screen, nothing to switch between.
-- Turns off every key that switches to, moves windows to, or moves workspaces.
-- Moving windows between screens stays: SUPER + SHIFT + arrows (see snap.lua),
-- or drag a window, or drag it between the screen cards in Alt + Tab.
-- To get workspaces back: delete require("hypr.no-workspaces") in hyprland.lua.

local function unbind(keys)
  pcall(hl.unbind, keys)
end

for n = 1, 10 do
  local key = "code:" .. tostring(n + 9) -- the number row, 1..0
  unbind("SUPER + " .. key)
  unbind("SUPER + SHIFT + " .. key)
  unbind("SUPER + SHIFT + ALT + " .. key)
end

for _, keys in ipairs({
  "SUPER + TAB",
  "SUPER + SHIFT + TAB",
  "SUPER + CTRL + TAB",
  "SUPER + mouse_down",
  "SUPER + mouse_up",
  "SUPER + SHIFT + ALT + LEFT",
  "SUPER + SHIFT + ALT + RIGHT",
  "SUPER + SHIFT + ALT + UP",
  "SUPER + SHIFT + ALT + DOWN",
}) do
  unbind(keys)
end
