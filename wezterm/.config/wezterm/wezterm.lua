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
	{ family = "Maple Mono", scale = 1.0 },
	{ family = "FiraCodeNerdFont", scale = 1.0 },
	{ family = "FiraCode Nerd Font", scale = 1.0 },
	{ family = "JetBrains Mono", scale = 1.0 },
	{ family = "Terminus", scale = 1.0 },
	{ family = "Noto Color Emoji", scale = 1.0 },
})
if wezterm.target_triple == "x86_64-unknown-linux-gnu" then
	config.window_decorations = "RESIZE"
else
	config.window_decorations = "TITLE | RESIZE"
end
config.window_close_confirmation = "AlwaysPrompt"
config.default_workspace = "main"

-- Dim inactive panes
config.inactive_pane_hsb = {
	saturation = 0.25,
	brightness = 0.5,
}

-- Track panes that rang the bell (Claude waiting/done). Cleared on focus.
local pane_bells = {}

wezterm.on("bell", function(_, pane)
	pane_bells[pane:pane_id()] = true
end)

local function pane_has_claude(pane)
	local info = pane:get_foreground_process_info()
	if not info then
		return false
	end
	for _, arg in ipairs(info.argv or {}) do
		if arg:match("claude") then
			return true
		end
	end
	return false
end

local function pane_is_working(pane)
	local text = pane:get_lines_as_text(30)
	return text:find("esc to interrupt", 1, true) ~= nil
end

local function workspace_status(name)
	local has_claude, waiting, working = false, false, false
	for _, win in ipairs(wezterm.mux.all_windows()) do
		if win:get_workspace() == name then
			for _, tab in ipairs(win:tabs()) do
				for _, p in ipairs(tab:panes()) do
					if pane_has_claude(p) then
						has_claude = true
						if pane_bells[p:pane_id()] then
							waiting = true
						end
						if pane_is_working(p) then
							working = true
						end
					end
				end
			end
		end
	end
	return has_claude, waiting, working
end

-- Keybinds
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- Navigate
	{ key = "g", mods = "LEADER", action = act.ScrollToTop },

	-- Send C-Space when pressing C-Space twice
	{ key = "Space", mods = "LEADER", action = act.SendKey({ key = "Space", mods = "CTRL" }) },
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
	{ key = "[", mods = "LEADER|CTRL", action = act.SwitchWorkspaceRelative(-1) },
	{ key = "]", mods = "LEADER|CTRL", action = act.SwitchWorkspaceRelative(1) },
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action_callback(function(window, pane)
			local choices = {
				{ label = wezterm.nerdfonts.md_plus .. " Create new workspace…", id = "__new__" },
			}
			for _, name in ipairs(wezterm.mux.get_workspace_names()) do
				local has_claude, waiting, working = workspace_status(name)
				local prefix = "  "
				if waiting then
					prefix = wezterm.nerdfonts.md_bell_ring .. " "
				elseif working then
					prefix = wezterm.nerdfonts.md_loading .. " "
				elseif has_claude then
					prefix = wezterm.nerdfonts.md_robot .. " "
				end
				table.insert(choices, { label = prefix .. name, id = name })
			end
			window:perform_action(
				act.InputSelector({
					title = "Switch workspace",
					choices = choices,
					fuzzy = true,
					action = wezterm.action_callback(function(inner_window, inner_pane, id)
						if not id then
							return
						end
						if id == "__new__" then
							inner_window:perform_action(
								act.PromptInputLine({
									description = "New workspace name",
									action = wezterm.action_callback(function(w, p, line)
										if line and line ~= "" then
											w:perform_action(act.SwitchToWorkspace({ name = line }), p)
										end
									end),
								}),
								inner_pane
							)
						else
							inner_window:perform_action(act.SwitchToWorkspace({ name = id }), inner_pane)
						end
					end),
				}),
				pane
			)
		end),
	},
	{
		key = "$",
		mods = "LEADER|SHIFT",
		action = act.PromptInputLine({
			description = "Enter new name for workspace",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					wezterm.mux.rename_workspace(window:mux_window():get_workspace(), line)
				end
			end),
		}),
	},

	-- Claude code
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\x1b\r") },

	-- Mac specific
	{ key = "LeftArrow", mods = "OPT", action = act.SendString("\x1bb") },
	{ key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") },

	-- Delete word backward
	{ key = "Backspace", mods = "CTRL", action = act.SendKey({ key = "w", mods = "CTRL" }) },
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
	-- Clear bell flag for the focused pane
	pane_bells[pane:pane_id()] = nil

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

	-- Workspace list with Claude state
	local active_ws = window:active_workspace()
	local right = {}
	for _, name in ipairs(wezterm.mux.get_workspace_names()) do
		local has_claude, waiting, working = workspace_status(name)
		if waiting then
			table.insert(right, { Foreground = { Color = custom_colors.red } })
			table.insert(right, { Text = wezterm.nerdfonts.md_bell_ring .. " " })
		elseif working then
			table.insert(right, { Foreground = { Color = custom_colors.yellow } })
			table.insert(right, { Text = wezterm.nerdfonts.md_loading .. " " })
		elseif has_claude then
			table.insert(right, "ResetAttributes")
			table.insert(right, { Text = wezterm.nerdfonts.md_robot .. " " })
		end
		if name == active_ws then
			table.insert(right, { Foreground = { Color = custom_colors.cyan } })
			table.insert(right, { Attribute = { Intensity = "Bold" } })
		else
			table.insert(right, "ResetAttributes")
		end
		table.insert(right, { Text = name })
		table.insert(right, "ResetAttributes")
		table.insert(right, { Text = "  " })
	end
	table.insert(right, { Text = "| " })
	table.insert(right, { Text = wezterm.nerdfonts.md_folder .. " " .. cwd })
	table.insert(right, { Text = " | " })
	table.insert(right, { Foreground = { Color = custom_colors.yellow } })
	table.insert(right, { Text = wezterm.nerdfonts.fa_code .. " " .. ccmd })
	table.insert(right, { Text = " | " })

	window:set_right_status(wezterm.format(right))
end)

return config
