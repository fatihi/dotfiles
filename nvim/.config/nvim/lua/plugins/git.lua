-- Git: changed lines in the sign column (gitsigns) and lazygit in a floating window
local pack = require("config.pack")

pack.add({ pack.gh("lewis6991/gitsigns.nvim") })

local map = vim.keymap.set

require("gitsigns").setup({
  on_attach = function(buf)
    local gs = require("gitsigns")
    local function bmap(mode, lhs, rhs, desc)
      map(mode, lhs, rhs, { buffer = buf, desc = desc })
    end
    bmap("n", "]h", function()
      gs.nav_hunk("next")
    end, "Next change (hunk)")
    bmap("n", "[h", function()
      gs.nav_hunk("prev")
    end, "Previous change (hunk)")
    bmap("n", "<leader>gs", gs.stage_hunk, "Stage/unstage hunk")
    bmap("x", "<leader>gs", function()
      gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Stage/unstage selected lines")
    bmap("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
    bmap("x", "<leader>gr", function()
      gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end, "Reset selected lines")
    bmap("n", "<leader>gS", gs.stage_buffer, "Stage file")
    bmap("n", "<leader>gR", gs.reset_buffer, "Reset file")
    bmap("n", "<leader>gp", gs.preview_hunk_inline, "Preview hunk")
    bmap("n", "<leader>gb", function()
      gs.blame_line({ full = true })
    end, "Blame line")
    bmap("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle inline blame")
    bmap("n", "<leader>gd", gs.diffthis, "Diff against index")
    bmap({ "o", "x" }, "ih", gs.select_hunk, "Hunk")
  end,
})

-- Git pickers (fzf-lua)
local fzf = require("fzf-lua")
map("n", "<leader>gf", fzf.git_status, { desc = "Changed files" })
map("n", "<leader>gc", fzf.git_commits, { desc = "Commits" })
map("n", "<leader>gC", fzf.git_bcommits, { desc = "Commits of this file" })

-- Lazygit in a floating terminal. Opening a file from lazygit (e) closes it and
-- opens the file here (os.editPreset in ~/.config/lazygit/config.yml).
local function lazygit()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
  })
  vim.fn.jobstart({ "lazygit" }, {
    term = true,
    on_exit = function()
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
vim.api.nvim_create_user_command("Lazygit", lazygit, { desc = "Open lazygit" })
map("n", "<leader>gg", lazygit, { desc = "Lazygit" })
