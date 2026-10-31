-- WezTerm configuration
-- Docs: https://wezfurlong.org/wezterm/config/files.html
-- wezterm reloads this file automatically when it changes.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font (JetBrains Mono ships with wezterm; DejaVu as fallback)
config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "DejaVu Sans Mono",
})
config.font_size = 11.0

-- Colours (any name from https://wezfurlong.org/wezterm/colorschemes/)
config.color_scheme = "Catppuccin Mocha"

-- Tab bar: simple style, hidden while only one tab is open
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true

-- Window
config.window_padding = { left = 6, right = 6, top = 4, bottom = 4 }
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "Disabled"

-- Scrollback
config.scrollback_lines = 10000

return config
