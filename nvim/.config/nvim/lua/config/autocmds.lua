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

-- Keep splits equal when the terminal is resized, in every tab. Runs in one
-- normal (non-floating) window of each tab without switching to it, so g<Tab>
-- still knows the previous tab and no BufEnter/WinEnter autocmds fire.
autocmd("VimResized", {
  group = group,
  callback = function()
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if vim.api.nvim_win_get_config(win).relative == "" then
          vim.api.nvim_win_call(win, function()
            vim.cmd("wincmd =")
          end)
          break
        end
      end
    end
  end,
})

-- Reload files changed outside Neovim (e.g. by lazygit or git checkout).
-- Not in the command-line window (q:), where :checktime isn't allowed.
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd.checktime()
    end
  end,
})

-- Close help, quickfix, man pages and :checkhealth with q
autocmd("FileType", {
  group = group,
  pattern = { "help", "qf", "man", "checkhealth" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", function()
      if not pcall(vim.cmd.close) then -- the last window can't be closed
        vim.cmd.bdelete()
      end
    end, { buffer = ev.buf, nowait = true, desc = "Close window" })
  end,
})

-- o / O on a comment line start a plain line, not another comment (Enter in
-- insert mode still continues the comment; gco / gcO add a comment line).
-- An autocmd because filetype plugins set formatoptions per buffer.
autocmd("FileType", {
  group = group,
  callback = function()
    vim.opt_local.formatoptions:remove("o")
  end,
})

-- Prose: wrap long lines and check spelling (z= suggestions, ]s / [s next/previous mistake)
autocmd("FileType", {
  group = group,
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})
