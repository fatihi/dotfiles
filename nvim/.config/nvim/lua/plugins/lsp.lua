-- Coding: language servers, completion, formatting, linting, diagnostics list
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  gh("mason-org/mason.nvim"), -- installs language servers and tools (:Mason)
  gh("neovim/nvim-lspconfig"), -- default settings for each language server
  gh("mason-org/mason-lspconfig.nvim"), -- enables the servers mason installed
  gh("folke/lazydev.nvim"), -- knows the Neovim Lua API when editing this config
  gh("DrKJeff16/wezterm-types"), -- the same for the wezterm config (via lazydev)
  gh("rafamadriz/friendly-snippets"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") }, -- release tags ship a prebuilt binary
  gh("stevearc/conform.nvim"),
  gh("mfussenegger/nvim-lint"),
  gh("folke/trouble.nvim"),
})

local map = vim.keymap.set

-- Languages: add the server to `servers` and its formatter/linter below.
-- Names: https://github.com/mason-org/mason-registry (or browse with :Mason)
local servers = { "lua_ls", "bashls" }
local tools = { "stylua", "shellcheck", "shfmt" } -- formatters and linters
local formatters_by_ft = {
  lua = { "stylua" },
  sh = { "shfmt" }, -- indent from .editorconfig, else the buffer's shiftwidth
  bash = { "shfmt" },
}
local linters_by_ft = {
  -- e.g. python = { "ruff" }. (shellcheck needs no entry: bashls runs it)
}

-- Mason: install everything listed above (in the background, on first start)
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = servers,
  automatic_enable = { exclude = { "stylua" } }, -- stylua runs through conform, not as a server
})
local registry = require("mason-registry")
registry.refresh(function()
  for _, name in ipairs(tools) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and not pkg:is_installed() then
      pkg:install()
    end
  end
end)

-- Server settings (merged with nvim-lspconfig's defaults)
vim.lsp.config("lua_ls", {
  settings = { Lua = { format = { enable = false } } }, -- stylua formats Lua
})

require("lazydev").setup({
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    { path = "wezterm-types", mods = { "wezterm" } }, -- in files that require("wezterm")
  },
})

-- Diagnostics: text at the end of the line, worst first, icons in the sign column
vim.diagnostic.config({
  severity_sort = true,
  virtual_text = true,
  float = { source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  },
})

-- Keys while a language server is attached. Built in since Neovim 0.11:
--   K = hover, grn = rename, gra = code action, grr = references,
--   gri = implementation, gO = symbols
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keys", { clear = true }),
  callback = function(ev)
    local fzf = require("fzf-lua")
    local function bmap(lhs, rhs, desc)
      map("n", lhs, rhs, { buffer = ev.buf, desc = desc })
    end
    bmap("gd", fzf.lsp_definitions, "Go to definition")
    bmap("gD", vim.lsp.buf.declaration, "Go to declaration")
    bmap("gy", fzf.lsp_typedefs, "Go to type definition")
    bmap("grr", fzf.lsp_references, "References")
    bmap("gri", fzf.lsp_implementations, "Implementations")
    bmap("<leader>cr", vim.lsp.buf.rename, "Rename")
    bmap("<leader>ca", fzf.lsp_code_actions, "Code action")
  end,
})

-- Completion: Ctrl+space = open, Ctrl+n/p = select, Ctrl+y = accept, Ctrl+e = close,
-- Tab / Shift+Tab = next/previous snippet field
require("blink.cmp").setup({
  keymap = { preset = "default" },
  completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
  signature = { enabled = true },
  sources = {
    default = { "lazydev", "lsp", "path", "snippets", "buffer" },
    providers = {
      lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
    },
  },
})
vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

-- Formatting: on save (falls back to the language server if no formatter is set)
local conform = require("conform")
conform.setup({
  formatters_by_ft = formatters_by_ft,
  formatters = {
    -- only in projects with a stylua.toml / .stylua.toml (like this config), so
    -- other Lua code (awesome, wezterm, ...) isn't reformatted to stylua's defaults
    stylua = { require_cwd = true },
  },
  format_on_save = function()
    if vim.g.autoformat == false then
      return
    end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
})
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" -- gq uses it too
map({ "n", "x" }, "<leader>cf", function()
  conform.format({ lsp_format = "fallback" })
end, { desc = "Format" })
map("n", "<leader>uf", function()
  vim.g.autoformat = vim.g.autoformat == false
  vim.notify("Format on save " .. (vim.g.autoformat and "on" or "off"))
end, { desc = "Toggle format on save" })

-- Linting: run linters when opening, saving and leaving insert mode
local lint = require("lint")
lint.linters_by_ft = linters_by_ft
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("lint", { clear = true }),
  callback = function()
    lint.try_lint()
  end,
})

-- Trouble: lists of diagnostics, symbols, references, quickfix
require("trouble").setup()
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (all)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Diagnostics (buffer)" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols" })
map("n", "<leader>xl", "<cmd>Trouble lsp toggle win.position=right<cr>", { desc = "LSP definitions/references" })
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location list" })
