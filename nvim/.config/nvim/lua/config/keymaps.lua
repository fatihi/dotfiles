-- General keys. Plugin keys are defined next to each plugin in lua/plugins/.
-- Press <Space> and wait to see them all (which-key), or <Space>fk to search them.
local map = vim.keymap.set

-- Esc also clears the search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>")

-- Save with Ctrl+s in any mode
map({ "n", "i", "x", "s" }, "<C-s>", "<cmd>write<cr><Esc>", { desc = "Save file" })

-- j/k move by screen line in wrapped text; with a count (5j, the relative
-- numbers) they still move by real lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- n always searches down and N up, also after ? (which normally swaps them);
-- zv opens a fold the match is in
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next match" })
map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next match" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Previous match" })
map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Previous match" })

-- Insert mode: , . ; end an undo step, so u undoes the last part of a sentence
-- instead of everything typed since entering insert mode (. still repeats all of it)
for _, c in ipairs({ ",", ".", ";" }) do
  map("i", c, c .. "<C-g>u")
end

-- New comment line below / above, in the language's comment style (gcc = toggle line)
map("n", "gco", "o<Esc>Vcx<Esc><cmd>normal gcc<cr>fxa<BS>", { desc = "Add comment below" })
map("n", "gcO", "O<Esc>Vcx<Esc><cmd>normal gcc<cr>fxa<BS>", { desc = "Add comment above" })

-- Splits (Ctrl+w s / Ctrl+w v)
map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })

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
map("n", "<leader>us", "<cmd>setlocal spell!<cr>", { desc = "Toggle spell check" })
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
-- Restart Neovim with the same windows and files, e.g. after changing this
-- config (asks about unsaved changes first). Neo-tree is closed before, it
-- doesn't survive being restored from a session.
map("n", "<leader>qr", function()
  pcall(function()
    require("neo-tree.command").execute({ action = "close" })
  end)
  vim.cmd.restart()
end, { desc = "Restart Neovim" })
