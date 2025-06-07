return {
	-- file explorer that lets you edit your filesystem like a normal buffer
	{
		"stevearc/oil.nvim",
		dependencies = {
			{ "nvim-tree/nvim-web-devicons" },
		},
		lazy = false,
		keys = {
			{ "-", ":Oil --float<CR>", desc = "Oil File manager" },
		},
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {
			columns = {
				"icon",
			},
			skip_confirm_for_simple_edits = true,
			view_options = {
				show_hidden = true,
				case_insensitive = true,
			},
		},
	},

	-- default file explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		lazy = false,
		keys = {
			{ "\\", ":Neotree reveal<CR>", desc = "NeoTree", silent = true },
		},
		opts = {
			filesystem = {
				window = {
					mappings = {
						["\\"] = "close_window",
					},
				},
			},
		},
	},
}
