local wezterm = require("wezterm")
local act = wezterm.action
local config = {}

-- Use config builder if possible
if wezterm.config_builder() then
	config = wezterm.config_builder()
end

-- Disable wayland
config.enable_wayland = false

-- Settings
config.color_scheme = "Gruvbox Dark (Gogh)"
local custom_colors = {
	red = "#D06F79",
	cyan = "#88C0D0",
	magenta = "#B48EAD",
	yellow = "#EBCB8B",
}
config.font = wezterm.font_with_fallback({
	{ family = "FiraCodeNerdFont", scale = 1.0 },
	{ family = "JetBrains Mono", scale = 1.0 },
	{ family = "Terminus", scale = 1.0 },
	{ family = "Noto Color Emoji", scale = 1.0 },
})
config.window_decorations = "RESIZE"
config.window_close_confirmation = "AlwaysPrompt"
config.default_workspace = "main"

-- Dim inactive panes
config.inactive_pane_hsb = {
	saturation = 0.25,
	brightness = 0.5,
}

-- Keybinds
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- Send C-a when pressing C-a twice
	{ key = "a", mods = "LEADER", action = act.SendKey({ key = "a", mods = "CTRL" }) },
	{ key = "c", mods = "LEADER", action = act.ActivateCopyMode },

	-- Panes
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "s", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	-- KeyTable for resizing panes
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- Tabs
	{ key = "n", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "t", mods = "LEADER", action = act.ShowTabNavigator },
	-- KeyTable for moving tabs around
	{ key = "m", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Workspaces
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- Claude code
	{ key = "Enter", mods = "SHIFT", action = wezterm.action({ SendString = "\x1b\r" }) },
}

-- Navigate tabs with index
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

config.key_tables = {
	resize_pane = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) },
		{ key = "k", action = act.MoveTabRelative(1) },
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- Tab bar
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
wezterm.on("update-status", function(window, pane)
	local shorten_name = function(s)
		return string.gsub(s, "(.*[/\\])(.*)", "%2")
	end

	-- Workspace name
	local stat = window:active_workspace()
	local stat_color = custom_colors.red

	if window:active_key_table() then
		stat = window.active_key_table()
		stat_color = custom_colors.cyan
	end

	if window:leader_is_active() then
		stat = "LDR"
		stat_color = custom_colors.magenta
	end

	-- Current working directory
	local cwd = pane:get_current_working_dir()
	cwd = cwd and shorten_name(cwd.file_path) or ""

	-- Current command
	local ccmd = pane:get_foreground_process_name()
	ccmd = ccmd and shorten_name(ccmd) or ""

	window:set_left_status(wezterm.format({
		{ Foreground = { Color = stat_color } },
		{ Text = " " },
		{ Text = wezterm.nerdfonts.oct_table .. " " .. stat },
		{ Text = " " },
	}))

	window:set_right_status(wezterm.format({
		{ Text = wezterm.nerdfonts.md_folder .. " " .. cwd },
		{ Text = " | " },
		{ Foreground = { Color = custom_colors.yellow } },
		{ Text = wezterm.nerdfonts.fa_code .. " " .. ccmd },
		{ Text = " | " },
	}))
end)

return config
