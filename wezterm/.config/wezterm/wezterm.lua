-- WezTerm configuration
-- Docs: https://wezfurlong.org/wezterm/config/files.html
-- wezterm reloads this file automatically when it changes.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Font (JetBrains Mono ships with wezterm; DejaVu as fallback)
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "DejaVu Sans Mono",
})
config.font_size = 11.0

-- Colours (any name from https://wezfurlong.org/wezterm/colorschemes/)
config.color_scheme = "Dracula (Official)"

-- Tab bar: simple style, always shown (its right side shows when the leader is active)
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true

-- " LEADER " on the right of the tab bar while Ctrl+a is waiting for the next key.
-- Checked every 250 ms so it shows up well within the 2 s leader timeout.
config.status_update_interval = 250
wezterm.on("update-status", function(window, _)
  if window:leader_is_active() then
    window:set_right_status(wezterm.format({
      { Background = { Color = "#ff79c6" } },  -- Dracula pink
      { Foreground = { Color = "#282a36" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " LEADER " },
    }))
  else
    window:set_right_status("")
  end
end)

-- Window
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
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
  -- Split: - = new pane below, \ = new pane to the right
  { key = "-",  mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "\\", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  -- Move between panes
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
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
  -- Ctrl+a twice sends a real Ctrl+a (start of line in bash)
  { key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },
}
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
end
-- Shift+h/j/k/l: resize the current pane
for key, dir in pairs({ H = "Left", J = "Down", K = "Up", L = "Right" }) do
  table.insert(config.keys, { key = key, mods = "LEADER", action = act.AdjustPaneSize({ dir, 5 }) })
end

return config
