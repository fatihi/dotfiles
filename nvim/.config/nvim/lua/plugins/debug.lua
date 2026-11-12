-- Debugging: nvim-dap (breakpoints, stepping), nvim-dap-view (panel with
-- variables, watches, call stack, breakpoints, REPL), nvim-dap-python.
-- Python works out of the box: debugpy is installed by mason (lua/plugins/lsp.lua),
-- and the program runs with the project's venv / .venv (or $VIRTUAL_ENV) if there is one.
-- Rust: rustaceanvim (lua/plugins/rust.lua) uses codelldb from mason.
-- Other languages need their debug adapter added to require("dap").adapters.
local pack = require("config.pack")
local gh = pack.gh

pack.add({
  gh("mfussenegger/nvim-dap"),
  gh("mfussenegger/nvim-dap-python"),
  gh("igorlfs/nvim-dap-view"),
})

local map = vim.keymap.set

-- Everything is set up on the first debug key, so nothing loads at startup.
-- (Use these keys, not :DapContinue, to start the first session.)
local ready = false
local function dap()
  if not ready then
    ready = true
    -- Signs: defined before nvim-dap loads, which keeps existing definitions
    vim.api.nvim_set_hl(0, "DapStoppedLine", { link = "Visual", default = true })
    local signs = { -- Nerd Font icons
      DapBreakpoint = { "\u{f111}", "DiagnosticError" }, -- circle
      DapBreakpointCondition = { "\u{f059}", "DiagnosticError" }, -- circled ?
      DapBreakpointRejected = { "\u{f05e}", "DiagnosticWarn" }, -- the adapter can't stop there
      DapLogPoint = { "\u{f075}", "DiagnosticInfo" }, -- speech bubble
      DapStopped = { "\u{f0055}", "DiagnosticWarn", "DapStoppedLine" }, -- arrow: paused here
    }
    for name, s in pairs(signs) do
      vim.fn.sign_define(name, { text = s[1], texthl = s[2], linehl = s[3] or "" })
    end

    -- The panel opens when a session starts and closes when it ends. Variable
    -- values are shown next to the code while paused.
    require("dap-view").setup({
      winbar = { default_section = "scopes", controls = { enabled = true } },
      virtual_text = { enabled = true },
      auto_toggle = true,
    })
    -- debugpy-adapter is on Neovim's PATH via mason. Tests run with pytest or
    -- unittest, depending on the project (pytest.ini / pyproject.toml).
    require("dap-python").setup("debugpy-adapter")
  end
  return require("dap")
end

local function call(fn, ...)
  local args = { ... }
  return function()
    dap()[fn](unpack(args))
  end
end

-- F keys as in most IDEs
map("n", "<F5>", call("continue"), { desc = "Debug: start/continue" })
map("n", "<F9>", call("toggle_breakpoint"), { desc = "Debug: toggle breakpoint" })
map("n", "<F10>", call("step_over"), { desc = "Debug: step over" })
map("n", "<F11>", call("step_into"), { desc = "Debug: step into" })
map("n", "<S-F11>", call("step_out"), { desc = "Debug: step out" })
map("n", "<F23>", call("step_out"), { desc = "Debug: step out" }) -- what some terminals send for Shift+F11

-- Space d: the same and more. Start with Space d c (asks what to run: this
-- file, this file with arguments, ...), or Space d m for the test under the cursor.
map("n", "<leader>db", call("toggle_breakpoint"), { desc = "Toggle breakpoint" })
map("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Break when: " }, function(cond)
    if cond and cond ~= "" then
      dap().set_breakpoint(cond)
    end
  end)
end, { desc = "Conditional breakpoint" })
map("n", "<leader>dL", function()
  vim.ui.input({ prompt = "Log message ({expr} for values): " }, function(msg)
    if msg and msg ~= "" then
      dap().set_breakpoint(nil, nil, msg)
    end
  end)
end, { desc = "Log point (prints, doesn't stop)" })
map("n", "<leader>dX", call("clear_breakpoints"), { desc = "Clear all breakpoints" })
map("n", "<leader>dc", call("continue"), { desc = "Start/continue" })
map("n", "<leader>dC", call("run_to_cursor"), { desc = "Run to cursor" })
map("n", "<leader>dl", call("run_last"), { desc = "Run last again" })
map("n", "<leader>di", call("step_into"), { desc = "Step into" })
map("n", "<leader>do", call("step_over"), { desc = "Step over" })
map("n", "<leader>dO", call("step_out"), { desc = "Step out" })
map("n", "<leader>dj", call("down"), { desc = "Down the call stack" })
map("n", "<leader>dk", call("up"), { desc = "Up the call stack" })
map("n", "<leader>dt", call("terminate"), { desc = "Stop" })
map("n", "<leader>du", function()
  dap()
  require("dap-view").toggle()
end, { desc = "Toggle debug panel" })
map({ "n", "x" }, "<leader>de", function()
  dap()
  require("dap-view").hover()
end, { desc = "Value of the expression (under cursor / selected)" })
map({ "n", "x" }, "<leader>dw", function()
  dap()
  require("dap-view").add_expr()
end, { desc = "Watch the expression (under cursor / selected)" })
map("n", "<leader>dr", function()
  dap()
  require("dap-view").jump_to_view("repl")
end, { desc = "REPL (run code in the paused program)" })

-- Python only: debug the test function / class the cursor is in, or the selected code
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dap_python_keys", { clear = true }),
  pattern = "python",
  callback = function(ev)
    local function bmap(mode, lhs, fn, desc)
      map(mode, lhs, function()
        if mode == "x" then
          vim.cmd("normal! \27") -- leave visual mode, so '< and '> mark the selection
        end
        dap()
        require("dap-python")[fn]()
      end, { buffer = ev.buf, desc = desc })
    end
    bmap("n", "<leader>dm", "test_method", "Debug test function")
    bmap("n", "<leader>dM", "test_class", "Debug test class")
    bmap("x", "<leader>ds", "debug_selection", "Debug selected code")
  end,
})

return { dap = dap } -- for lua/plugins/rust.lua
