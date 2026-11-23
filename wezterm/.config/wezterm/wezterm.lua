-- WezTerm configuration
-- Docs: https://wezfurlong.org/wezterm/config/files.html
-- wezterm reloads this file automatically when it changes.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Font (JetBrains Mono ships with wezterm; DejaVu as fallback). Icons come from
-- the system's Symbols Nerd Font: the copy built into wezterm is older and lacks
-- newer icons (e.g. some used by Neovim plugins).
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Symbols Nerd Font Mono",
  "DejaVu Sans Mono",
})
config.font_size = 11.0

-- Colours (any name from https://wezfurlong.org/wezterm/colorschemes/)
config.color_scheme = "Dracula (Official)"

-- Tab bar: simple style, always shown (its right side shows when the leader is active)
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.tab_max_width = 25

-- Mode indicator on the right of the tab bar: " LEADER " while Ctrl+a is
-- waiting for the next key, " COPY " / " SEARCH " / " RESIZE " in those modes.
-- Checked every 500 ms so it shows up well within the 2 s leader timeout.
config.status_update_interval = 500
local modes = {  -- Dracula colours
  copy_mode   = { text = " COPY ",   color = "#f1fa8c" },  -- yellow
  search_mode = { text = " SEARCH ", color = "#50fa7b" },  -- green
  resize_pane = { text = " RESIZE ", color = "#ffb86c" },  -- orange
}
wezterm.on("update-status", function(window, _)
  local mode = window:leader_is_active() and { text = " LEADER ", color = "#ff79c6" }  -- pink
    or modes[window:active_key_table()]
  if mode then
    window:set_right_status(wezterm.format({
      { Background = { Color = mode.color } },
      { Foreground = { Color = "#282a36" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = mode.text },
    }))
  else
    window:set_right_status("")
  end
end)

-- Tab titles: " 1: title ", like the default, but without the "Copy mode: " /
-- "Search: " prefix wezterm adds while a mode is active (the indicator shows it)
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
  local title = tab.tab_title
  if not title or title == "" then title = tab.active_pane.title end
  title = title:gsub("^Copy mode: ", ""):gsub("^Search: ", "")
  return wezterm.truncate_right(" " .. (tab.tab_index + 1) .. ": " .. title .. " ", max_width)
end)

-- Window
config.window_padding = { left = 6, right = 6, top = 4, bottom = 0 }
-- Ctrl+= / Ctrl+- change the text size only, not the window size
config.adjust_window_size_when_changing_font_size = false
-- Dim panes that don't have focus
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }
-- Ask before closing, except when only a shell is running in it
config.window_close_confirmation = "AlwaysPrompt"

-- Bell: short flash of the cursor instead of a sound
config.audible_bell = "Disabled"
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = "CursorColor",
}

-- Installed from the distro package, so don't check GitHub for new versions
config.check_for_updates = false

-- Scrollback
config.scrollback_lines = 10000

-- Panes and tabs: press Ctrl+a, then a key below (within 2 seconds)
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }
config.keys = {
  -- Split: - = new pane below, | = new pane to the right
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  -- Move between panes
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  -- r = resize mode: h/j/k/l resize the current pane (Shift = bigger steps)
  -- until Esc, Enter or q; see config.key_tables below
  { key = "r", mods = "LEADER", action = act.ActivateKeyTable({
    name = "resize_pane", one_shot = false,
  }) },
  -- Zoom the current pane to the full window and back
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  -- Close the current pane (asks if something other than a shell runs in it)
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  -- Tabs: c = new, n/p = next/previous, , = rename
  -- (1-9 = go to tab and Shift+h/j/k/l = resize pane are added below)
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = ",", mods = "LEADER", action = act.PromptInputLine({
    description = "Tab name (empty = automatic):",
    action = wezterm.action_callback(function(window, _, line)
      if line then window:active_tab():set_title(line) end
    end),
  }) },
  -- Move the current tab left/right
  { key = "{", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) },
  { key = "}", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },
  -- Pick a pane by its label: q = jump to it, s = swap it with the current one
  { key = "q", mods = "LEADER", action = act.PaneSelect },
  { key = "s", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
  -- [ = copy mode (scroll and select with vim keys, y copies, Esc leaves)
  -- / = search the scrollback, f = quick select (pick a URL, hash or path to copy)
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
  { key = "f", mods = "LEADER", action = act.QuickSelect },
  -- Ctrl+a twice sends a real Ctrl+a (start of line in bash)
  { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
}
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
end
-- Mouse: a click only selects text; Ctrl+click opens a link
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE",
    action = act.CompleteSelection("ClipboardAndPrimarySelection") },
  { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },
  -- swallow the press so Ctrl+click doesn't start a selection
  { event = { Down = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.Nop },
}

-- Direction keys, as a list: loops below use ipairs, not pairs, because the
-- order of pairs() is not fixed. wezterm numbers each action_callback in the
-- order it is created and loads this file more than once, so a changing order
-- sent keys to the wrong callback (Alt+h resized downwards).
local directions = {
  { key = "h", arrow = "LeftArrow", dir = "Left" },
  { key = "j", arrow = "DownArrow", dir = "Down" },
  { key = "k", arrow = "UpArrow", dir = "Up" },
  { key = "l", arrow = "RightArrow", dir = "Right" },
}

-- Shift+h/j/k/l: resize the current pane
for _, d in ipairs(directions) do
  table.insert(config.keys, { key = d.key:upper(), mods = "LEADER", action = act.AdjustPaneSize({ d.dir, 5 }) })
end

-- Resize mode (Ctrl+a r): stays active until Esc/Enter/q (not "until_unknown":
-- pressing Shift alone counts as an unknown key and would end the mode)
local resize_keys = {
  { key = "Escape", action = act.PopKeyTable },
  { key = "Enter", action = act.PopKeyTable },
  { key = "q", action = act.PopKeyTable },
}
for _, d in ipairs(directions) do
  table.insert(resize_keys, { key = d.key, action = act.AdjustPaneSize({ d.dir, 1 }) })
  table.insert(resize_keys, { key = d.arrow, action = act.AdjustPaneSize({ d.dir, 1 }) })
  table.insert(resize_keys, { key = d.key:upper(), action = act.AdjustPaneSize({ d.dir, 5 }) })
end
config.key_tables = { resize_pane = resize_keys }

-- Without the leader: Ctrl+h/j/k/l = move to the pane in that direction,
-- Ctrl+Arrow keys = resize the pane. When Neovim runs in the pane, the key goes to
-- Neovim instead (smart-splits.nvim), which moves between its splits and hands
-- back to wezterm at the edge. Neovim announces itself via the IS_NVIM user var.
local function is_nvim(pane)
  return pane:get_user_vars().IS_NVIM == "true"
end
for _, d in ipairs(directions) do
  for _, m in ipairs({
    { key = d.key, mods = "CTRL", action = act.ActivatePaneDirection(d.dir) },
    { key = d.arrow, mods = "CTRL", action = act.AdjustPaneSize({ d.dir, 3 }) },
  }) do
    local key, mods, action = m.key, m.mods, m.action
    table.insert(config.keys, {
      key = key,
      mods = mods,
      action = wezterm.action_callback(function(window, pane)
        if is_nvim(pane) then
          window:perform_action(act.SendKey({ key = key, mods = mods }), pane)
        else
          window:perform_action(action, pane)
        end
      end),
    })
  end
end

return config
