-- Coding: language servers, completion, formatting, linting, diagnostics list
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  gh("mason-org/mason.nvim"), -- installs language servers and tools (:Mason)
  gh("neovim/nvim-lspconfig"), -- default settings for each language server
  gh("mason-org/mason-lspconfig.nvim"), -- enables the servers mason installed
  gh("folke/lazydev.nvim"), -- knows the Neovim Lua API when editing this config
  gh("DrKJeff16/wezterm-types"), -- the same for the wezterm config (via lazydev)
  gh("b0o/SchemaStore.nvim"), -- JSON/YAML schemas for jsonls and yamlls
  gh("rafamadriz/friendly-snippets"),
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") }, -- release tags ship a prebuilt binary
  gh("stevearc/conform.nvim"),
  gh("mfussenegger/nvim-lint"),
  gh("folke/trouble.nvim"),
})

local map = vim.keymap.set

-- Languages: add the server to `servers` and its formatter/linter below.
-- Names: https://github.com/mason-org/mason-registry (or browse with :Mason)
-- jsonls and yamlls are installed with npm (needs Node.js), the others are binaries or Python.
local servers = {
  "lua_ls",
  "bashls",
  "jsonls", -- JSON, checked against its schema (SchemaStore), e.g. .luarc.json
  "yamlls", -- YAML, the same, e.g. lazygit's config.yml
  "taplo", -- TOML
  "basedpyright", -- Python: types, completion, go to definition
  "ruff", -- Python: lint (as a server) and format (via conform below)
}
local tools = { "stylua", "shellcheck", "shfmt" } -- formatters and linters
-- Not listed: the language server formats (JSON, YAML, TOML)
local formatters_by_ft = {
  lua = { "stylua" },
  sh = { "shfmt" }, -- indent from .editorconfig, else the buffer's shiftwidth
  bash = { "shfmt" },
  python = { "ruff_organize_imports", "ruff_format" },
}
local linters_by_ft = {
  -- e.g. markdown = { "markdownlint" }. (shellcheck and ruff need no entry: bashls / the ruff server run them)
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

vim.lsp.config("jsonls", {
  settings = { json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } } },
})
vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- SchemaStore.nvim provides the catalog instead
      schemas = require("schemastore").yaml.schemas(),
    },
  },
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

-- Jump to the next (dir = 1) / previous (-1) use of the symbol under the cursor,
-- wrapping around at the end of the file. Ctrl+o goes back.
local function jump_reference(dir)
  local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  local client = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/documentHighlight" })[1]
  if not client then
    return
  end
  local params = vim.lsp.util.make_position_params(win, client.offset_encoding)
  client:request("textDocument/documentHighlight", params, function(err, result)
    if err or not result or #result == 0 or vim.api.nvim_get_current_win() ~= win then
      return
    end
    -- LSP positions are 0-based and counted in the server's encoding; convert to
    -- {row (1-based), byte column}, as nvim_win_get_cursor uses
    local function pos(p)
      local line = vim.api.nvim_buf_get_lines(buf, p.line, p.line + 1, false)[1] or ""
      return { p.line + 1, vim.str_byteindex(line, client.offset_encoding, p.character, false) }
    end
    local function before(a, b)
      return a[1] < b[1] or (a[1] == b[1] and a[2] < b[2])
    end
    local refs = {}
    for _, h in ipairs(result) do
      table.insert(refs, { s = pos(h.range.start), e = pos(h.range["end"]) })
    end
    table.sort(refs, function(a, b)
      return before(a.s, b.s)
    end)
    local cursor = vim.api.nvim_win_get_cursor(win)
    -- Going back starts from the beginning of the use the cursor is on, so that
    -- one is skipped even when the cursor is in its middle
    local from = cursor
    for _, r in ipairs(refs) do
      if not before(cursor, r.s) and before(cursor, r.e) then
        from = r.s
      end
    end
    local target
    if dir > 0 then
      for _, r in ipairs(refs) do
        if before(cursor, r.s) then
          target = r
          break
        end
      end
      target = target or refs[1]
    else
      for i = #refs, 1, -1 do
        if before(refs[i].s, from) then
          target = refs[i]
          break
        end
      end
      target = target or refs[#refs]
    end
    vim.cmd("normal! m'") -- add to the jumplist
    vim.api.nvim_win_set_cursor(win, target.s)
  end, buf)
end

-- Keys while a language server is attached. Built in since Neovim 0.11:
--   K = hover, grn = rename, gra = code action, grr = references,
--   gri = implementation, gO = symbols
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp_keys", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name == "ruff" then
      client.server_capabilities.hoverProvider = false -- K shows basedpyright's hover instead
    end
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

    -- Other uses of the symbol under the cursor are highlighted when the cursor
    -- rests (updatetime); ]] / [[ jump to the next / previous one
    if client and client:supports_method("textDocument/documentHighlight", ev.buf) then
      local group = vim.api.nvim_create_augroup("lsp_highlight_" .. ev.buf, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group,
        buffer = ev.buf,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        buffer = ev.buf,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd("LspDetach", {
        group = group,
        buffer = ev.buf,
        callback = function(detach)
          if #vim.lsp.get_clients({ bufnr = detach.buf, method = "textDocument/documentHighlight" }) <= 1 then
            vim.lsp.buf.clear_references()
            vim.api.nvim_del_augroup_by_id(group)
          end
        end,
      })
      bmap("]]", function()
        jump_reference(1)
      end, "Next use of this symbol")
      bmap("[[", function()
        jump_reference(-1)
      end, "Previous use of this symbol")
    end
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
