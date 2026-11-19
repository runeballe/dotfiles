-- Windows-style snapping for floating windows (Rune).
--
--   Drag a window by its titlebar (no SUPER needed on floating workspaces) and drop it:
--     on the top bar strip          -> maximize
--     against the left/right edge   -> left/right half
--     ...in the top/bottom fifth    -> quarter (corner)
--   Drag a snapped window away      -> it gets its old size back
--
--   SUPER + LEFT/RIGHT -> snap half (tiled windows: move focus, as before)
--   SUPER + UP         -> maximize; again -> move to the screen above (tiled: focus up)
--   SUPER + SHIFT + arrows -> move window to the screen that way, keeping its snap
--   SUPER + DOWN       -> restore, or minimize if not snapped (tiled: focus down)
--
--   Snap Assist: after a half/quarter snap, the other windows tile up in the
--   empty side; click one to fill it, Esc or any other click cancels.

local M = {}

local EDGE = 16   -- px from a side edge that counts as "against the edge"
local GAP = 0     -- no space between snapped windows (borders are inset, see zone_rect)

local saved = {}  -- address -> { w, h } size before the window was snapped
local snapped = {} -- address -> zone name
local pressed = nil

local function logical(monitor)
  local w = monitor.width / monitor.scale
  local h = monitor.height / monitor.scale
  if (monitor.transform or 0) % 2 == 1 then
    w, h = h, w
  end
  return monitor.x, monitor.y, w, h
end

-- The usable area of a monitor: everything but the bar.
local function work_area(monitor)
  local x, y, w, h = logical(monitor)
  local r = monitor.reserved or {}
  x = x + (r.left or 0)
  y = y + (r.top or 0)
  w = w - (r.left or 0) - (r.right or 0)
  h = h - (r.top or 0) - (r.bottom or 0)
  return x, y, w, h
end

local function maximized(window)
  return (window.fullscreen or 0) ~= 0
end

local function set_maximized(window, on)
  hl.dispatch(hl.dsp.window.fullscreen({ mode = "maximized", action = on and "set" or "unset", window = window }))
end

local function place(window, x, y, w, h)
  hl.dispatch(hl.dsp.window.resize({ x = math.floor(w), y = math.floor(h), relative = false, window = window }))
  hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), relative = false, window = window }))
end

-- Leaving maximized takes a moment; geometry set before it lands gets overwritten.
local function after_unmaximize(window, fn)
  if maximized(window) then
    set_maximized(window, false)
    hl.timer(fn, { type = "oneshot", timeout = 150 })
  else
    fn()
  end
end

local function remember(window)
  if not snapped[window.address] and not maximized(window) then
    saved[window.address] = { w = window.size.x, h = window.size.y }
  end
end

-- { x, y, w, h } of a snap zone on a monitor.
local function zone_rect(monitor, zone)
  local x, y, w, h = work_area(monitor)
  x, y, w, h = x + GAP, y + GAP, w - 2 * GAP, h - 2 * GAP
  local hw, hh = (w - GAP) / 2, (h - GAP) / 2
  local right, bottom = x + hw + GAP, y + hh + GAP

  local zones = {
    left = { x, y, hw, h },
    right = { right, y, hw, h },
    topleft = { x, y, hw, hh },
    topright = { right, y, hw, hh },
    bottomleft = { x, bottom, hw, hh },
    bottomright = { right, bottom, hw, hh },
  }
  local z = zones[zone]
  if not z then
    return nil
  end
  -- Borders draw outside the window, so shrink by the border width: neighbours then touch exactly.
  local ok, b = pcall(hl.get_config, "general.border_size")
  b = (ok and tonumber(b)) or 0
  return { z[1] + b, z[2] + b, z[3] - 2 * b, z[4] - 2 * b }
end

function M.snap(window, zone, monitor)
  monitor = monitor or window.monitor
  if not window or not monitor then
    return
  end

  remember(window)

  if zone == "max" then
    snapped[window.address] = "max"
    set_maximized(window, true)
    return
  end

  local z = zone_rect(monitor, zone)
  if z then
    snapped[window.address] = zone
    after_unmaximize(window, function()
      place(window, z[1], z[2], z[3], z[4])
    end)
  end
end

-- Put a snapped window back at its old size, under the cursor so the drag feels continuous.
function M.restore(window, under_cursor)
  local addr = window.address
  local size = saved[addr]
  snapped[addr] = nil
  after_unmaximize(window, function()
    if not size then
      return
    end
    if under_cursor then
      local c = hl.get_cursor_pos()
      place(window, c.x - size.w / 2, c.y - 15, size.w, size.h)
    else
      hl.dispatch(hl.dsp.window.resize({ x = size.w, y = size.h, relative = false, window = window }))
      hl.dispatch(hl.dsp.window.center({ window = window }))
    end
  end)
end

-- Which zone the cursor is in, if any.
local function zone_at(c, monitor)
  local mx, my, mw, mh = logical(monitor)
  local top_strip = my + ((monitor.reserved or {}).top or 0) + 4

  local at_left = c.x <= mx + EDGE
  local at_right = c.x >= mx + mw - EDGE
  local fifth = mh / 5
  local upper = c.y <= my + fifth
  local lower = c.y >= my + mh - fifth

  if at_left or at_right then
    local side = at_left and "left" or "right"
    if upper then return "top" .. side end
    if lower then return "bottom" .. side end
    return side
  end

  if c.y <= top_strip then
    return "max"
  end

  return nil
end

-- Snap Assist: after a window snaps to one side, the other windows on the
-- workspace line up as tiles in the empty side. Click one to fill that side;
-- Esc, or a click anywhere else, puts them all back.
local ASSIST_PAD = 20
local assist = nil -- { snapped = addr, zone = remaining zone, monitor, items = { addr -> {x,y,w,h} }, order = { addr... } }

local function by_address(addr)
  return "address:" .. addr
end

local function put(addr, x, y, w, h)
  local sel = by_address(addr)
  hl.dispatch(hl.dsp.window.resize({ x = math.floor(w), y = math.floor(h), relative = false, window = sel }))
  hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), relative = false, window = sel }))
end

local function remaining_zone(zone)
  if zone == "left" or zone == "topleft" or zone == "bottomleft" then
    return "right"
  elseif zone == "right" or zone == "topright" or zone == "bottomright" then
    return "left"
  end
end

local function side_of(zone)
  return zone and (zone:find("left") and "left" or zone:find("right") and "right") or nil
end

local function assist_end(chosen)
  local a = assist
  assist = nil
  if not a then
    return
  end

  for _, addr in ipairs(a.order) do
    local g = a.items[addr]
    if addr == chosen then
      saved[addr] = { w = g.w, h = g.h } -- restoring later gives back its real size, not the tile size
      snapped[addr] = a.zone
      local z = zone_rect(a.monitor, a.zone)
      put(addr, z[1], z[2], z[3], z[4])
    else
      put(addr, g.x, g.y, g.w, g.h)
    end
  end

  if not chosen then
    hl.dispatch(hl.dsp.focus({ window = by_address(a.snapped) }))
  end
end

function M.assist(window, zone, monitor)
  monitor = monitor or window.monitor
  local remaining = remaining_zone(zone)
  if not remaining or not monitor then
    return
  end

  local ws = window.workspace
  local candidates = {}
  for _, w in ipairs(hl.get_workspace_windows(tostring(ws.id)) or {}) do
    if w.address ~= window.address and w.mapped and w.floating and not w.pinned and not maximized(w) then
      -- The empty side is already taken by a snapped window: nothing to assist with.
      if side_of(snapped[w.address]) == side_of(remaining) then
        return
      end
      table.insert(candidates, w)
    end
  end

  if #candidates == 0 then
    return
  end

  -- Only one other window: nothing to choose between, so it simply fills the
  -- empty side (a lone "pick me" tile just looks like a snap with a gap).
  if #candidates == 1 then
    local w = candidates[1]
    remember(w)
    snapped[w.address] = remaining
    local z = zone_rect(monitor, remaining)
    after_unmaximize(w, function()
      put(w.address, z[1], z[2], z[3], z[4])
    end)
    return
  end

  local area = zone_rect(monitor, remaining)
  local ax, ay, aw, ah = area[1], area[2], area[3], area[4]
  local n = #candidates
  local cols = math.max(1, math.min(n, math.floor(math.sqrt(n * aw / ah) + 0.5)))
  local rows = math.ceil(n / cols)
  local cw = (aw - ASSIST_PAD * (cols + 1)) / cols
  local ch = (ah - ASSIST_PAD * (rows + 1)) / rows

  assist = { snapped = window.address, zone = remaining, monitor = monitor, items = {}, order = {} }

  for i, w in ipairs(candidates) do
    assist.items[w.address] = { x = w.at.x, y = w.at.y, w = w.size.x, h = w.size.y }
    table.insert(assist.order, w.address)
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    put(w.address, ax + ASSIST_PAD + col * (cw + ASSIST_PAD), ay + ASSIST_PAD + row * (ch + ASSIST_PAD), cw, ch)
  end
end

local function snap_and_assist(window, zone, monitor)
  M.snap(window, zone, monitor)
  if zone ~= "max" then
    M.assist(window, zone, monitor)
  end
end


local function on_press()
  -- Focus moves with the click; read the window a tick later to get the one being grabbed.
  hl.timer(function()
    local w = hl.get_active_window()
    if assist then
      pressed = nil
      assist_end(w and assist.items[w.address] and w.address or nil)
      return
    end
    if w and w.floating then
      local c = hl.get_cursor_pos()
      pressed = { address = w.address, x = w.at.x, y = w.at.y, sw = w.size.x, sh = w.size.y, max = maximized(w), cx = c.x, cy = c.y }
    else
      pressed = nil
    end
  end, { type = "oneshot", timeout = 1 })
end

local function on_release()
  local p = pressed
  pressed = nil
  if not p then
    return
  end

  local window = hl.get_active_window()
  if not window or window.address ~= p.address or not window.floating then
    return
  end

  local c = hl.get_cursor_pos()
  local travelled = math.abs(c.x - p.cx) + math.abs(c.y - p.cy)
  if travelled < 30 then
    return -- a click, not a drag
  end

  local monitor = hl.get_monitor_at_cursor()
  local zone = monitor and zone_at(c, monitor)

  -- A maximized window can't follow the mouse; dragging it off the top un-maximizes
  -- it under the cursor (or straight into whatever zone it was dropped on).
  if p.max then
    if p.cy - p.y > 48 then
      return -- dragging inside the window (selecting text etc.), not by its titlebar
    end
    if zone and zone ~= "max" then
      snap_and_assist(window, zone, monitor)
    elseif not zone then
      M.restore(window, true)
    end
    return
  end

  -- A resize keeps one corner of the window where it was; a move keeps none.
  -- (Size alone can't tell: Chromium shrinks itself while being dragged out of a snap.)
  local x2, y2 = window.at.x + window.size.x, window.at.y + window.size.y
  local px2, py2 = p.x + p.sw, p.y + p.sh
  local h_fixed = window.at.x == p.x or x2 == px2
  local v_fixed = window.at.y == p.y or y2 == py2
  local resized = window.size.x ~= p.sw or window.size.y ~= p.sh
  if resized and h_fixed and v_fixed then
    return
  end
  if window.at.x == p.x and window.at.y == p.y then
    return -- didn't move
  end

  if zone then
    snap_and_assist(window, zone, monitor)
  elseif snapped[window.address] then
    M.restore(window, true)
  end
end

-- Move a floating window to the monitor in a direction, keeping it snapped/maximized
-- the same way there. Returns false if there is no monitor that way.
function M.to_monitor(window, direction)
  local target = hl.get_monitor(direction)
  if not target or not window.monitor or target.name == window.monitor.name then
    return false
  end

  local addr = window.address
  local sel = "address:" .. addr

  -- A maximized window moves as it is and stays maximized on the other screen.
  if maximized(window) then
    snapped[addr] = "max"
    hl.dispatch(hl.dsp.window.move({ monitor = target.name, window = sel }))
    hl.dispatch(hl.dsp.focus({ window = sel }))
    return true
  end

  local zone = snapped[addr]
  hl.dispatch(hl.dsp.window.move({ monitor = target.name, window = sel }))
  hl.timer(function()
    for _, w in ipairs(hl.get_windows() or {}) do
      if w.address == addr then
        if zone then
          snapped[addr] = nil -- re-snap fresh on the new monitor, keeping the remembered size
          M.snap(w, zone, target)
        else
          hl.dispatch(hl.dsp.window.center({ window = sel }))
        end
        hl.dispatch(hl.dsp.focus({ window = sel }))
      end
    end
  end, { type = "oneshot", timeout = 150 })
  return true
end

-- Keyboard: floating windows snap, tiled ones keep the old focus behavior.
local function key(direction)
  return function()
    assist_end(nil)
    local w = hl.get_active_window()
    if not w or not w.floating then
      hl.dispatch(hl.dsp.focus({ direction = direction }))
      return
    end

    local current = snapped[w.address]
    if maximized(w) then
      current = "max"
    end
    if direction == "u" then
      if current == "max" then
        M.to_monitor(w, "u") -- already maximized: send it up to the screen above
        return
      end
      if current == "bottomleft" then return M.snap(w, "left") end
      if current == "bottomright" then return M.snap(w, "right") end
      if current == "left" then return M.snap(w, "topleft") end
      if current == "right" then return M.snap(w, "topright") end
      return M.snap(w, "max")
    elseif direction == "d" then
      if current == "max" then return M.restore(w, false) end
      if current == "topleft" then return M.snap(w, "left") end
      if current == "topright" then return M.snap(w, "right") end
      if current == "left" then return M.snap(w, "bottomleft") end
      if current == "right" then return M.snap(w, "bottomright") end
      if current then return M.restore(w, false) end
      hl.exec_cmd("omarchy-hyprland-window-minimize " .. w.address)
    elseif direction == "l" then
      if current == "right" or current == "topright" or current == "bottomright" then
        return M.restore(w, false)
      end
      return snap_and_assist(w, "left")
    elseif direction == "r" then
      if current == "left" or current == "topleft" or current == "bottomleft" then
        return M.restore(w, false)
      end
      return snap_and_assist(w, "right")
    end
  end
end

hl.on("window.destroy", function(window)
  if window and window.address then
    saved[window.address] = nil
    snapped[window.address] = nil
  end
end)

hl.on("workspace.active", function()
  assist_end(nil)
end)

o.bind("ESCAPE", "Snap Assist: cancel", function()
  assist_end(nil)
end, { non_consuming = true, transparent = true })

local passthrough = { non_consuming = true, transparent = true, ignore_mods = true }
o.bind("mouse:272", "Snap: remember drag start", on_press, passthrough)
o.bind("mouse:272", "Snap: drop window into zone", on_release,
  { non_consuming = true, transparent = true, ignore_mods = true, release = true })

-- SUPER + SHIFT + arrows: move a floating window to the screen that way (like Win+Shift+arrows);
-- tiled windows keep Omarchy's swap.
local function monitor_key(direction)
  return function()
    assist_end(nil)
    local w = hl.get_active_window()
    if not w or not w.floating then
      hl.dispatch(hl.dsp.window.swap({ direction = direction }))
      return
    end
    M.to_monitor(w, direction)
  end
end

o.rebind("SUPER + SHIFT + LEFT", "Window to left screen / swap left", monitor_key("l"))
o.rebind("SUPER + SHIFT + RIGHT", "Window to right screen / swap right", monitor_key("r"))
o.rebind("SUPER + SHIFT + UP", "Window to screen above / swap up", monitor_key("u"))
o.rebind("SUPER + SHIFT + DOWN", "Window to screen below / swap down", monitor_key("d"))

o.rebind("SUPER + LEFT", "Snap left / focus left", key("l"))
o.rebind("SUPER + RIGHT", "Snap right / focus right", key("r"))
o.rebind("SUPER + UP", "Maximize / focus up", key("u"))
o.rebind("SUPER + DOWN", "Restore or minimize / focus down", key("d"))

M.assist_end = function(addr) assist_end(addr) end

return M
