return {
	-- collection of small plugins
	"echasnovski/mini.nvim",
	version = "*",
	config = function()
		-- better around/inside
		require("mini.ai").setup({ n_lines = 500 })

		-- add/delete/replace surroundings
		require("mini.surround").setup()

		-- status line
		local statusline = require("mini.statusline")
		statusline.setup({ use_icons = vim.g.have_nerd_font })

		statusline.section_location = function()
			return "%2l:%-2v"
		end
	end,
}
