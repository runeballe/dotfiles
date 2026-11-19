-- SUPER + D: show the desktop, like Win + D (Rune).
-- First press minimizes every window on the workspaces you can see (all monitors)
-- to the dock; second press brings exactly those windows back where they were.
-- A window you bring back yourself from the dock in between is simply left alone.
--
-- What was hidden is remembered as a tag on each window, not in Lua memory:
-- Hyprland reloads its config now and then, and that wipes Lua state.

local MINIMIZED = "special:minimized"
local TAG = "rune-show-desktop"
local FROM = "omarchy-minimized-from-" -- Omarchy's own tag, so the dock knows where each one belongs

local function sel(addr)
  return "address:" .. addr
end

local function tags_of(w)
  local t = {}
  for _, tag in ipairs(w.tags or {}) do
    t[(tag:gsub("%*$", ""))] = true
  end
  return t
end

local function from_workspace(w)
  for tag in pairs(tags_of(w)) do
    local id = tag:sub(1, #FROM) == FROM and tag:sub(#FROM + 1):match("^%d+$") -- plain prefix: "-" is magic in Lua patterns
    if id then
      return id
    end
  end
end

local function on_minimized(w)
  return w.workspace and w.workspace.name == MINIMIZED
end

local function hidden_by_us()
  local list = {}
  for _, w in ipairs(hl.get_windows() or {}) do
    if on_minimized(w) and tags_of(w)[TAG] then
      table.insert(list, w)
    end
  end
  return list
end

local function restore(list)
  local here = hl.get_active_workspace and hl.get_active_workspace()
  for _, w in ipairs(list) do
    local ws = from_workspace(w) or (here and here.id and here.id >= 1 and tostring(here.id)) or nil
    hl.dispatch(hl.dsp.window.tag({ tag = "-" .. TAG, window = sel(w.address) }))
    if ws then
      hl.dispatch(hl.dsp.window.tag({ tag = "-" .. FROM .. ws, window = sel(w.address) }))
      hl.dispatch(hl.dsp.window.move({ workspace = ws, follow = false, window = sel(w.address) }))
    end
  end
end

local function minimize_all()
  -- A window brought back from the dock still carries the tag; drop it so it isn't
  -- mistaken for one we hid.
  for _, w in ipairs(hl.get_windows() or {}) do
    if not on_minimized(w) and tags_of(w)[TAG] then
      hl.dispatch(hl.dsp.window.tag({ tag = "-" .. TAG, window = sel(w.address) }))
    end
  end

  local focused = hl.get_monitor_at_cursor()
  local focused_ws = nil

  for _, monitor in ipairs(hl.get_monitors() or {}) do
    local ws = monitor.active_workspace
    if ws and ws.id and ws.id >= 1 then
      if focused and monitor.name == focused.name then
        focused_ws = ws.id
      end
      for _, w in ipairs(hl.get_workspace_windows(tostring(ws.id)) or {}) do
        if w.mapped and not w.pinned then
          hl.dispatch(hl.dsp.window.tag({ tag = "+" .. TAG, window = sel(w.address) }))
          hl.dispatch(hl.dsp.window.tag({ tag = "+" .. FROM .. ws.id, window = sel(w.address) }))
          hl.dispatch(hl.dsp.window.move({ workspace = MINIMIZED, follow = false, window = sel(w.address) }))
        end
      end
    end
  end

  -- Focus would otherwise stay on a hidden window, which pops the minimized
  -- workspace up on screen (Omarchy's own minimize does the same).
  if focused_ws then
    hl.dispatch(hl.dsp.focus({ workspace = tostring(focused_ws) }))
  end
end

local function toggle()
  local list = hidden_by_us()
  if #list > 0 then
    restore(list)
  else
    minimize_all()
  end
end

o.bind("SUPER + D", "Show desktop (minimize all / restore)", toggle)

return { toggle = toggle }
