local wezterm = require("wezterm")

local config = {}

-- Use config builder if possible
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- Settings
config.color_scheme = "SeaShells"
config.font = wezterm.font("FiraCode")

-- Disable wayland for gnome decorations

config.enable_wayland = false

return config
