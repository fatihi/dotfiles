-- Look: colours, icons, statusline, key hints, indent guides, start screen
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  gh("nvim-mini/mini.nvim"), -- collection of small modules (icons, starter, pairs, ...)
  gh("Mofiqul/dracula.nvim"),
  gh("nvim-lualine/lualine.nvim"),
  gh("folke/which-key.nvim"),
  gh("lukas-reineke/indent-blankline.nvim"),
  gh("folke/persistence.nvim"), -- here because the start screen offers to restore a session
})

-- Icons (also stands in for nvim-web-devicons, which lualine/neo-tree/fzf-lua look for)
require("mini.icons").setup()
MiniIcons.mock_nvim_web_devicons()

-- Colours: Dracula, like the rest of the desktop
require("dracula").setup({ italic_comment = true })
vim.cmd.colorscheme("dracula")

-- Statusline
require("lualine").setup({
  options = {
    theme = "dracula-nvim",
    globalstatus = true,
    component_separators = "",
    section_separators = { left = "", right = "" },
  },
  sections = {
    -- lsp_status: attached language servers, with a spinner while they're busy (e.g. indexing)
    lualine_x = { "lsp_status", "encoding", "fileformat", "filetype" },
  },
  extensions = { "oil", "neo-tree", "trouble", "fzf", "quickfix" },
})

-- Key hints: press <Space> (or any prefix like g, [, ]) and wait
local wk = require("which-key")
wk.setup({
  preset = "modern",
  spec = {
    { "<leader>b", group = "buffer" },
    { "<leader>c", group = "code" },
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
    { "<leader>q", group = "session/quit" },
    { "<leader>u", group = "toggle" },
    { "<leader>x", group = "diagnostics/lists" },
    { "gs", group = "surround" },
  },
})
vim.keymap.set("n", "<leader>?", function()
  wk.show({ global = false })
end, { desc = "Keys for this buffer" })

-- Indent guides, with the current scope highlighted
require("ibl").setup({
  indent = { char = "│" },
  scope = { show_start = false, show_end = false },
  exclude = { filetypes = { "ministarter", "help", "trouble", "neo-tree", "oil", "grug-far", "bigfile" } },
})

-- Colour previews: #rrggbb is shown in its own colour
local hipatterns = require("mini.hipatterns")
hipatterns.setup({
  highlighters = { hex_color = hipatterns.gen_highlighter.hex_color() },
})

-- Sessions: saved automatically per folder when quitting. Not when files were
-- given ("nvim .bashrc" would replace this folder's session with that one file),
-- unless a session is restored by hand afterwards. "nvim ." still saves.
local persistence = require("persistence")
persistence.setup()
for _, arg in ipairs(vim.fn.argv()) do
  if vim.fn.isdirectory(arg) == 0 then
    persistence.stop()
    break
  end
end
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("persistence_restart", { clear = true }),
  pattern = "PersistenceLoadPost",
  callback = function()
    persistence.start()
  end,
})
vim.keymap.set("n", "<leader>qs", persistence.load, { desc = "Restore session (this folder)" })
vim.keymap.set("n", "<leader>ql", function()
  persistence.load({ last = true })
end, { desc = "Restore last session" })
vim.keymap.set("n", "<leader>qS", persistence.select, { desc = "Pick a session" })
vim.keymap.set("n", "<leader>qd", persistence.stop, { desc = "Don't save this session" })

-- Start screen (when Neovim is opened without a file). Type the highlighted
-- letters to pick an entry, or move with arrow keys / Ctrl+n/p and press Enter.
local starter = require("mini.starter")
starter.setup({
  evaluate_single = true,
  items = {
    { section = "Session", name = "Restore session (this folder)", action = persistence.load },
    {
      section = "Session",
      name = "Last session",
      action = function()
        persistence.load({ last = true })
      end,
    },
    { section = "Actions", name = "Find file", action = "FzfLua files" },
    { section = "Actions", name = "Grep text", action = "FzfLua live_grep" },
    { section = "Actions", name = "Explorer", action = "Oil" },
    { section = "Actions", name = "Lazygit", action = "Lazygit" },
    { section = "Actions", name = "New file", action = "enew" },
    { section = "Actions", name = "Quit", action = "qall" },
    starter.sections.recent_files(8, true, false), -- recent files in this folder
  },
  content_hooks = {
    starter.gen_hook.adding_bullet("  "),
    starter.gen_hook.aligning("center", "center"),
  },
})
