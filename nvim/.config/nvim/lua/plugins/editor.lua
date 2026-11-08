-- Editing: treesitter, text objects, surround, pairs, jumping, split navigation, ...
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects"), version = "main" },
  gh("folke/flash.nvim"),
  gh("mrjones2014/smart-splits.nvim"),
  gh("nvim-lua/plenary.nvim"), -- library used by todo-comments and neo-tree
  gh("folke/todo-comments.nvim"),
  gh("MeanderingProgrammer/render-markdown.nvim"),
})

local map = vim.keymap.set

-- Treesitter: highlighting, indentation and folds from a real parser.
-- Parsers are compiled locally (needs the tree-sitter CLI and a C compiler).
-- More languages: add them here, or :TSInstall <language>.
-- stylua: ignore
local parsers = {
  "bash", "c", "css", "diff", "git_config", "git_rebase", "gitcommit", "gitignore",
  "html", "ini", "json", "lua", "luadoc", "markdown", "markdown_inline", "python", "query",
  "rasi", "regex", "toml", "vim", "vimdoc", "yaml",
}
if vim.fn.executable("tree-sitter") == 1 and vim.fn.executable("cc") == 1 then
  require("nvim-treesitter").install(parsers) -- only installs missing ones, in the background
else
  vim.notify("treesitter: install tree-sitter and gcc to compile parsers", vim.log.levels.WARN)
end
-- Files over 1 MB (logs, minified JSON, ...) get no treesitter, indent guides,
-- colour previews or language servers, so they open and scroll fast
local big_file = 1024 * 1024
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter", { clear = true }),
  callback = function(ev)
    local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(ev.buf))
    if stat and stat.size > big_file then
      vim.b[ev.buf].big_file = true -- language servers check this (lua/plugins/lsp.lua)
      vim.opt_local.foldmethod = "manual" -- the treesitter foldexpr would parse the whole file
      vim.b[ev.buf].minihipatterns_disable = true
      require("ibl").setup_buffer(ev.buf, { enabled = false })
      return
    end
    if pcall(vim.treesitter.start, ev.buf) then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

-- Text objects: va) vi" etc. get smarter, plus treesitter-based ones:
--   af/if = function, ac/ic = class, ao/io = if/loop, aa/ia = argument (built in)
local ai = require("mini.ai")
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    o = ai.gen_spec.treesitter({
      a = { "@conditional.outer", "@loop.outer" },
      i = { "@conditional.inner", "@loop.inner" },
    }),
  },
})

-- ]f / [f: next / previous function (start). Also after an operator, e.g. d]f.
-- The jumps go to the jumplist, so Ctrl+o goes back.
local move = require("nvim-treesitter-textobjects.move")
map({ "n", "x", "o" }, "]f", function()
  move.goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function" })
map({ "n", "x", "o" }, "[f", function()
  move.goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous function" })

-- Surround on gs (s is flash): gsa = add, gsd = delete, gsr = replace
--   e.g. gsaiw" = put "" around the word, gsd" = remove them, gsr"' = " -> '
require("mini.surround").setup({
  mappings = {
    add = "gsa",
    delete = "gsd",
    find = "gsf",
    find_left = "gsF",
    highlight = "gsh",
    replace = "gsr",
    update_n_lines = "gsn",
  },
})

-- Close brackets and quotes automatically
require("mini.pairs").setup()

-- Delete buffers but keep the window layout (plain :bdelete also closes the split)
local bufremove = require("mini.bufremove")
bufremove.setup()
map("n", "<leader>bd", function()
  bufremove.delete()
end, { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.bo[buf].buflisted then
      bufremove.delete(buf)
    end
  end
end, { desc = "Delete other buffers" })

-- Flash: press s and 1-2 characters, then the label shown at the target
local flash = require("flash")
flash.setup()
map({ "n", "x", "o" }, "s", flash.jump, { desc = "Flash jump" })
map({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash select treesitter node" })
map("o", "r", flash.remote, { desc = "Flash remote (e.g. yr<jump>iw)" })
map("c", "<C-s>", flash.toggle, { desc = "Toggle flash in / search" })

-- Ctrl+h/j/k/l: move between splits, and on into WezTerm panes at the edge
-- Alt+h/j/k/l: resize the split (or the WezTerm pane)
local ss = require("smart-splits")
ss.setup({ move = { at_edge = "stop" } })
map("n", "<C-h>", ss.move_cursor_left, { desc = "Go to left split/pane" })
map("n", "<C-j>", ss.move_cursor_down, { desc = "Go to lower split/pane" })
map("n", "<C-k>", ss.move_cursor_up, { desc = "Go to upper split/pane" })
map("n", "<C-l>", ss.move_cursor_right, { desc = "Go to right split/pane" })
map("n", "<A-h>", ss.resize_left, { desc = "Resize split left" })
map("n", "<A-j>", ss.resize_down, { desc = "Resize split down" })
map("n", "<A-k>", ss.resize_up, { desc = "Resize split up" })
map("n", "<A-l>", ss.resize_right, { desc = "Resize split right" })

-- TODO / FIXME / HACK / NOTE comments: highlighted, ]t / [t to jump
local todo = require("todo-comments")
todo.setup()
map("n", "]t", todo.jump_next, { desc = "Next TODO comment" })
map("n", "[t", todo.jump_prev, { desc = "Previous TODO comment" })
map("n", "<leader>ft", "<cmd>TodoFzfLua<cr>", { desc = "TODO comments" })
map("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "TODO comments (Trouble)" })

-- Markdown: headings, lists, tables, code blocks rendered in normal mode.
-- The cursor line and insert mode always show the raw text.
require("render-markdown").setup({
  latex = { enabled = false }, -- would need a LaTeX parser and utftex/latex2text
})
map("n", "<leader>um", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle markdown rendering" })
