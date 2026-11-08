vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- No plugins written in Python/Node/Ruby/Perl are used, so don't look for them
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0

local o = vim.opt

-- Line numbers: absolute on the cursor line, relative elsewhere (for 5j, 12k, ...)
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes" -- always shown, so text doesn't jump when git/diagnostic signs appear

-- Keep 8 lines visible above/below the cursor (and 8 columns to the side)
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false

-- Undo history survives closing the file
o.undofile = true

-- Use the system clipboard for y/p (set after startup, the clipboard check is slow)
vim.schedule(function()
  o.clipboard = "unnamedplus"
end)

-- Search: case-insensitive unless the pattern has a capital letter
o.ignorecase = true
o.smartcase = true
o.inccommand = "split" -- live preview of :s/// in a split

-- Indent: 4 spaces by default (filetype plugins and .editorconfig can override)
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.softtabstop = 4

-- Show tabs, trailing spaces and non-breaking spaces
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.fillchars = { eob = " " } -- no ~ after the end of the buffer

-- Splits open to the right / below
o.splitright = true
o.splitbelow = true

-- Folding by treesitter, all folds open when a file is opened
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldtext = "" -- show the first line of the fold with its highlighting
o.foldlevel = 99

o.winborder = "rounded" -- borders around floating windows (hover, diagnostics, ...)
o.laststatus = 3 -- one statusline for all windows
o.showmode = false -- lualine shows the mode
o.confirm = true -- ask to save instead of failing on :q with changes
o.updatetime = 250 -- faster CursorHold (gitsigns, LSP highlights)
o.timeoutlen = 400 -- which-key pops up after this long
