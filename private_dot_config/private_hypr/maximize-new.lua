-- New windows open maximized.
--
-- Skipped: dialogs (modal windows such as file pickers and confirm boxes) and
-- apps that Omarchy floats on purpose at their own size (o.floating_apps:
-- calculator, pickers, popups ...). Same exclusion Omarchy's workspace modes use.

local function not_floating_on_their_own(match)
  local floating = o.floating_apps or { class = {}, title = {}, tags = {}, tagged = {} }
  local excluded = { class = {}, title = {} }
  for _, key in ipairs({ "class", "title" }) do
    for _, pattern in ipairs(floating[key]) do
      table.insert(excluded[key], pattern)
    end
  end
  for tag in pairs(floating.tags) do
    for _, tagged in ipairs(floating.tagged[tag] or {}) do
      table.insert(excluded[tagged.key], tagged.pattern)
    end
  end
  for _, key in ipairs({ "class", "title" }) do
    local patterns = excluded[key]
    if #patterns > 0 then
      local alternatives = {}
      for _, pattern in ipairs(patterns) do
        table.insert(alternatives, "(?:" .. pattern .. ")")
      end
      match[key] = "negative:" .. table.concat(alternatives, "|")
    end
  end
  return match
end

o.window(not_floating_on_their_own({ modal = false }), { maximize = true })
