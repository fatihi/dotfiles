-- Small helpers around the built-in plugin manager (vim.pack)
local M = {}

-- gh("owner/repo") -> GitHub URL
function M.gh(repo)
  return "https://github.com/" .. repo
end

-- Install (without asking) and load plugins
function M.add(specs)
  vim.pack.add(specs, { confirm = false })
end

-- Build steps after a plugin was updated
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("pack_hooks", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    end
  end,
})

return M
