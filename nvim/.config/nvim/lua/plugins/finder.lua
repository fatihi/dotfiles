-- Finding things: fzf-lua (fuzzy finder), oil (folder as a buffer), neo-tree (sidebar)
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  gh("ibhagwan/fzf-lua"),
  gh("stevearc/oil.nvim"),
  gh("MunifTanjim/nui.nvim"), -- UI library for neo-tree
  { src = gh("nvim-neo-tree/neo-tree.nvim"), version = "v3.x" },
})

local map = vim.keymap.set

-- fzf-lua runs the real fzf, so the keys and colours (FZF_DEFAULT_OPTS from
-- .bashrc) are the same as in the shell
local fzf = require("fzf-lua")
fzf.setup({
  fzf_opts = { ["--height"] = "100%", ["--border"] = "none" }, -- override .bashrc's values
  winopts = { preview = { layout = "flex" } },
})
fzf.register_ui_select() -- use fzf for vim.ui.select (code actions, ...)

map("n", "<leader><space>", fzf.files, { desc = "Find files" })
map("n", "<leader>ff", fzf.files, { desc = "Files" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Grep" })
map("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word under cursor" })
map("x", "<leader>fw", fzf.grep_visual, { desc = "Grep selection" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })
map("n", "<leader>f/", fzf.blines, { desc = "Lines in this buffer" })
map("n", "<leader>fh", fzf.helptags, { desc = "Help" })
map("n", "<leader>fk", fzf.keymaps, { desc = "Key bindings" })
map("n", "<leader>fc", fzf.commands, { desc = "Commands" })
map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Diagnostics (buffer)" })
map("n", "<leader>fD", fzf.diagnostics_workspace, { desc = "Diagnostics (all)" })
map("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Symbols (buffer)" })
map("n", "<leader>fS", fzf.lsp_live_workspace_symbols, { desc = "Symbols (project)" })
map("n", "<leader>fR", fzf.resume, { desc = "Resume last search" })
map("n", "<leader>fn", function()
  fzf.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Neovim config files" })

-- Oil: edit a folder like a text file. Rename = edit the line, delete = dd,
-- new file = new line, then :w to apply. "-" goes up a folder.
-- Also opens for "nvim ." and ":e somefolder".
require("oil").setup({
  view_options = { show_hidden = true },
  float = { padding = 4 },
})
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent folder (oil)" })

-- Neo-tree: classic file tree sidebar (a to add, d delete, r rename, ? for help)
require("neo-tree").setup({
  close_if_last_window = true,
  filesystem = {
    hijack_netrw_behavior = "disabled", -- oil handles opening folders
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    filtered_items = { hide_dotfiles = false },
  },
})
-- Close it before a session is saved, otherwise restoring brings back a broken, empty tree
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("neo_tree_session", { clear = true }),
  pattern = "PersistenceSavePre",
  callback = function()
    require("neo-tree.command").execute({ action = "close" })
  end,
})
-- Reveals the current file (asks to change the working folder if the file is
-- outside it). In buffers that aren't files (start screen, oil, help, ...) it
-- just opens the working folder, instead of trying to reveal e.g. "ministarter://1"
map("n", "<leader>e", function()
  local name = vim.api.nvim_buf_get_name(0)
  local is_file = vim.bo.buftype == "" and name ~= "" and not name:match("^%a+://")
  require("neo-tree.command").execute(is_file and { toggle = true } or { toggle = true, dir = vim.uv.cwd() })
end, { desc = "File tree" })
