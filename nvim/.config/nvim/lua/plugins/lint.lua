return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = lint.linters_by_ft or {}
      lint.linters_by_ft['markdown'] = { 'markdownlint' }
      lint.linters_by_ft['inko'] = nil
      lint.linters_by_ft['janet'] = nil
      lint.linters_by_ft['ruby'] = nil

      local ensure_installed = {}

      for _, linters in pairs(lint.linters_by_ft) do
        for _, linter in pairs(linters) do
          vim.list_extend(ensure_installed, {
            linter,
          })
        end
      end

      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
