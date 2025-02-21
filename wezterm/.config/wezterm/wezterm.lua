local wezterm = require("wezterm")

local config = {}

-- Use config builder if possible
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Settings
config.color_scheme = "tokyonight_night"
config.font = wezterm.font("FiraCode Nerd Font")

return config
