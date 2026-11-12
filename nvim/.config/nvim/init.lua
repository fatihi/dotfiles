-- Neovim configuration (needs Neovim 0.12+ for the built-in plugin manager vim.pack)
-- Plugins are installed on first start; versions are pinned in nvim-pack-lock.json.
-- Update them with :lua vim.pack.update()

require("config.options") -- also sets the leader key, so it must come first
require("config.keymaps")
require("config.autocmds")
require("config.terminal")

-- Plugins, grouped by topic (ui first: it sets up the icons the others use)
require("plugins.ui")
require("plugins.editor")
require("plugins.finder")
require("plugins.lsp")
require("plugins.git")
require("plugins.debug")
