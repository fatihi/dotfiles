return {
  'zk-org/zk-nvim',
  config = function()
    require('zk').setup {
      picker = 'telescope',
    }

    vim.keymap.set('n', '<leader>zn', "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", { desc = 'Create new note' })
    vim.keymap.set('n', '<leader>zo', "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", { desc = 'Open notes' })
    vim.keymap.set('n', '<leader>zt', '<Cmd>ZkTags<CR>', { desc = 'Open notes with the selected tags' })
    vim.keymap.set('n', '<leader>zf', "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>", { desc = 'Open notes' })
    vim.keymap.set('v', '<leader>zf', ":'<,'>ZkMatch<CR>", { desc = 'Search for notes matching current visual selection' })
  end,
}
