-- Terminals: a shell split toggled with <leader>t, floating terminals (used for
-- lazygit), and keys inside terminals: <Esc><Esc> = back to normal mode,
-- Ctrl+h/j/k/l = move to the next split (or WezTerm pane)
local M = {}

-- In the editor's middle, 90% of its size
local function float_config()
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
  }
end

-- Run cmd in a floating terminal that closes when the program exits.
-- The program gets every key (no <Esc><Esc> / Ctrl+h/j/k/l from below).
function M.float(cmd)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.b[buf].term_keys = false
  local win = vim.api.nvim_open_win(buf, true, float_config())
  local group = vim.api.nvim_create_augroup("float_term_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_config(win, float_config())
      end
    end,
  })
  -- Coming back to the window: keys go to the program again, not to Neovim
  vim.api.nvim_create_autocmd("BufEnter", { group = group, buffer = buf, command = "startinsert" })
  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end,
  })
  vim.cmd.startinsert()
end

-- One shell in a split at the bottom; hiding it keeps the shell running.
-- (Typing exit closes it, the next toggle starts a new one.)
local shell = { buf = nil, win = nil }
function M.toggle_shell()
  if shell.win and vim.api.nvim_win_is_valid(shell.win) then
    if not pcall(vim.api.nvim_win_hide, shell.win) then -- the last window can't be hidden
      vim.notify("The terminal is the last window", vim.log.levels.WARN)
      return
    end
    shell.win = nil
    return
  end
  vim.cmd("botright 15split")
  shell.win = vim.api.nvim_get_current_win()
  vim.wo[shell.win].winfixheight = true -- keeps its height when splits are equalized
  if shell.buf and vim.api.nvim_buf_is_valid(shell.buf) then
    vim.api.nvim_win_set_buf(shell.win, shell.buf)
  else
    vim.cmd.terminal()
    shell.buf = vim.api.nvim_get_current_buf()
    vim.bo[shell.buf].buflisted = false -- not in the buffer list / [b ]b
  end
  vim.cmd.startinsert()
end
vim.keymap.set("n", "<leader>t", M.toggle_shell, { desc = "Terminal" })

-- Every other terminal (the shell split, :terminal) gets the keys below, except
-- fzf-lua's and the floating ones, where fzf/lazygit need Esc and Ctrl+j/k
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("terminal", { clear = true }),
  callback = function(ev)
    vim.schedule(function() -- fzf-lua sets its filetype after the terminal opened
      if
        not vim.api.nvim_buf_is_valid(ev.buf)
        or vim.b[ev.buf].term_keys == false
        or vim.bo[ev.buf].filetype == "fzf"
      then
        return
      end
      local win = vim.fn.bufwinid(ev.buf)
      if win ~= -1 then
        vim.wo[win].number = false
        vim.wo[win].relativenumber = false
        vim.wo[win].signcolumn = "no"
      end
      local function tmap(lhs, rhs, desc)
        vim.keymap.set("t", lhs, rhs, { buffer = ev.buf, desc = desc })
      end
      local ss = require("smart-splits")
      tmap("<Esc><Esc>", "<C-\\><C-n>", "Leave terminal mode")
      tmap("<C-h>", ss.move_cursor_left, "Go to left split/pane")
      tmap("<C-j>", ss.move_cursor_down, "Go to lower split/pane")
      tmap("<C-k>", ss.move_cursor_up, "Go to upper split/pane")
      tmap("<C-l>", ss.move_cursor_right, "Go to right split/pane")
    end)
  end,
})

return M
