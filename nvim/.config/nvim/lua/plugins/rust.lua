-- Rust: rustaceanvim (rust-analyzer with its extras: runnables, debuggables,
-- grouped code actions, macro expansion, ...) and crates.nvim (Cargo.toml).
-- rust-analyzer comes from rustup ("rustup component add rust-analyzer", done by
-- install.sh), so it matches the toolchain. rustfmt formats on save (lua/plugins/lsp.lua),
-- codelldb (from mason) is the debugger.
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  { src = gh("mrcjkb/rustaceanvim"), version = vim.version.range("9.*") }, -- starts itself in Rust files
  { src = gh("saecki/crates.nvim"), version = vim.version.range("0.*") },
})

local map = vim.keymap.set

-- Server settings (rustaceanvim merges vim.lsp.config, also the blink.cmp
-- capabilities set for "*" in lua/plugins/lsp.lua)
vim.lsp.config("rust-analyzer", {
  settings = {
    ["rust-analyzer"] = {
      check = { command = "clippy" }, -- clippy's lints on save, not only cargo check's errors
      cargo = { allFeatures = true },
    },
  },
})

-- Keys in Rust buffers (on top of the general LSP keys)
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("rust_keys", { clear = true }),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client or client.name ~= "rust-analyzer" then
      return
    end
    local function bmap(lhs, cmd, desc, needs_dap)
      map("n", lhs, function()
        if needs_dap then
          require("plugins.debug").dap() -- panel, signs, ...
        end
        vim.cmd("RustLsp " .. cmd)
      end, { buffer = ev.buf, desc = desc })
    end
    bmap("K", "hover actions", "Hover (with actions: run, debug, go to impl, ...)")
    bmap("<leader>ca", "codeAction", "Code action") -- rust-analyzer's grouped actions
    bmap("<leader>ce", "explainError current", "Explain the error (rustc --explain)")
    bmap("<leader>cE", "renderDiagnostic current", "Diagnostic as cargo prints it")
    bmap("<leader>cm", "expandMacro", "Expand macro")
    bmap("<leader>cp", "parentModule", "Parent module")
    bmap("<leader>co", "openCargo", "Open Cargo.toml")
    bmap("<leader>cD", "openDocs", "Open docs.rs for the symbol")
    bmap("<leader>cR", "runnables", "Run (binary, test, example, ...)")
    bmap("<leader>cT", "testables", "Run tests")
    bmap("<leader>cl", "run", "Run the target under the cursor")
    bmap("<leader>dm", "debug", "Debug the test/main under the cursor", true)
    bmap("<leader>dM", "debuggables", "Debug (pick binary, test, ...)", true)
  end,
})

-- Cargo.toml: crate versions as diagnostics (outdated, yanked), completion of
-- crate names, versions and features, K for crate info, Space c a to update / upgrade
require("crates").setup({
  lsp = { enabled = true, actions = true, completion = true, hover = true },
  completion = { crates = { enabled = true } }, -- search crates.io while typing the name
})
