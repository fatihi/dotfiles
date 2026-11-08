local group = vim.api.nvim_create_augroup("config", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlight yanked text
autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Reopen files at the last cursor position
autocmd("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local ft = vim.bo[ev.buf].filetype
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) and not ft:match("^git") then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Keep splits equal when the terminal is resized
autocmd("VimResized", {
  group = group,
  command = "tabdo wincmd =",
})

-- Reload files changed outside Neovim (e.g. by lazygit or git checkout)
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  command = "checktime",
})
