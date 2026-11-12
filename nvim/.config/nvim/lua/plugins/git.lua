-- Git: changed lines in the sign column (gitsigns), git pickers and lazygit in a floating window
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

-- Git pickers (snacks.picker)
map("n", "<leader>gf", function()
  Snacks.picker.git_status()
end, { desc = "Changed files" })
map("n", "<leader>gc", function()
  Snacks.picker.git_log()
end, { desc = "Commits" })
map("n", "<leader>gC", function()
  Snacks.picker.git_log_file()
end, { desc = "Commits of this file" })

-- Lazygit in a floating terminal (lua/config/terminal.lua). Opening a file from
-- lazygit (e) closes it and opens the file here (os.editPreset in ~/.config/lazygit/config.yml).
local function lazygit()
  require("config.terminal").float({ "lazygit" })
end
vim.api.nvim_create_user_command("Lazygit", lazygit, { desc = "Open lazygit" })
map("n", "<leader>gg", lazygit, { desc = "Lazygit" })
