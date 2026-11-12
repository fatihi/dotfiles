-- Finding things: snacks.picker (fuzzy finder; set up in lua/plugins/ui.lua),
-- oil (folder as a buffer), neo-tree (sidebar)
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  gh("stevearc/oil.nvim"),
  gh("MunifTanjim/nui.nvim"), -- UI library for neo-tree
  { src = gh("nvim-neo-tree/neo-tree.nvim"), version = "v3.x" },
})

local map = vim.keymap.set

-- pick("files") -> function that opens the files picker
local function pick(source, opts)
  return function()
    Snacks.picker.pick(source, opts)
  end
end

map("n", "<leader><space>", pick("files"), { desc = "Find files" })
map("n", "<leader>ff", pick("files"), { desc = "Files" })
map("n", "<leader>fg", pick("grep"), { desc = "Grep" })
map({ "n", "x" }, "<leader>fw", pick("grep_word"), { desc = "Grep word under cursor / selection" })
map("n", "<leader>fb", pick("buffers"), { desc = "Buffers" })
map("n", "<leader>fr", pick("recent"), { desc = "Recent files" })
map("n", "<leader>f/", pick("lines"), { desc = "Lines in this buffer" })
map("n", "<leader>fh", pick("help"), { desc = "Help" })
map("n", "<leader>fk", pick("keymaps"), { desc = "Key bindings" })
map("n", "<leader>fc", pick("commands"), { desc = "Commands" })
map("n", "<leader>fd", pick("diagnostics_buffer"), { desc = "Diagnostics (buffer)" })
map("n", "<leader>fD", pick("diagnostics"), { desc = "Diagnostics (all)" })
map("n", "<leader>fs", pick("lsp_symbols"), { desc = "Symbols (buffer)" })
map("n", "<leader>fS", pick("lsp_workspace_symbols"), { desc = "Symbols (project)" })
map("n", "<leader>fR", pick("resume"), { desc = "Resume last search" })
map("n", "<leader>fn", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Neovim config files" })

-- Oil: edit a folder like a text file. Rename = edit the line, delete = dd,
-- new file = new line, then :w to apply. "-" opens it in a popup; in there,
-- "-" goes up a folder, Enter opens a file (closing the popup), q closes it.
-- "nvim ." and ":e somefolder" open it in the window instead of a popup.
require("oil").setup({
  view_options = { show_hidden = true },
  float = { padding = 4 },
  keymaps = { q = { "actions.close", mode = "n" } },
})
map("n", "-", "<cmd>Oil --float<cr>", { desc = "Open parent folder (oil)" })

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
