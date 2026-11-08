-- General keys. Plugin keys are defined next to each plugin in lua/plugins/.
-- Press <Space> and wait to see them all (which-key), or <Space>fk to search them.
local map = vim.keymap.set

-- Esc also clears the search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>")

-- Save with Ctrl+s in any mode
map({ "n", "i", "x", "s" }, "<C-s>", "<cmd>write<cr><Esc>", { desc = "Save file" })

-- Visual mode: keep the selection after indenting, move selected lines with J/K
map("x", "<", "<gv")
map("x", ">", ">gv")
map("x", "J", ":move '>+1<cr>gv=gv", { desc = "Move lines down", silent = true })
map("x", "K", ":move '<-2<cr>gv=gv", { desc = "Move lines up", silent = true })

-- Buffers: [b / ]b switch (built in), <leader>bd / <leader>bo in lua/plugins/editor.lua

-- Diagnostics ([d / ]d jump, built in)
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

-- Toggles
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle line wrap" })
map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
map("n", "<leader>uv", function()
  local on = not not vim.diagnostic.config().virtual_lines -- nil at first, and nil wouldn't turn virtual_text off
  vim.diagnostic.config({ virtual_lines = not on, virtual_text = on })
end, { desc = "Toggle diagnostics below the line" })
map("n", "<leader>uh", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

-- Undo tree (ships with Neovim 0.12)
map("n", "<leader>uu", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd.Undotree()
end, { desc = "Undo tree" })

map("n", "<leader>qq", "<cmd>qall<cr>", { desc = "Quit all" })
