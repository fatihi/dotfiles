-- configure leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- is nerd font configured in terminal
vim.g.have_nerd_font = true

-- line numbers
vim.o.number = true
vim.o.relativenumber = true

-- set how many characters tab should be
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2

-- enable mouse mode
vim.o.mouse = "a"

-- mode will be shown in status line
vim.o.showmode = false

-- sync clipboard between Neovim and OS
vim.schedule(function()
	vim.o.clipboard = "unnamedplus"
end)

-- break long lines
vim.o.breakindent = true

-- save undo history
vim.o.undofile = true

-- case-insensitive search unless one char is upper case
vim.o.ignorecase = true
vim.o.smartcase = true

-- enable sign column
vim.o.signcolumn = "yes"

-- decrease update time
vim.o.updatetime = 250

-- decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- configure splits
vim.o.splitright = true
vim.o.splitbelow = true

-- change whitespace display characters
vim.o.list = true
vim.opt.listchars = {
	tab = "» ",
	trail = "·",
	nbsp = "␣",
}

-- preview substitutions
vim.o.inccommand = "split"

-- show line of cursor
vim.o.cursorline = true

-- minimal number of lines above and below cursor
vim.o.scrolloff = 10

-- raise dialog when doing operation with unsaved changes
vim.o.confirm = true
