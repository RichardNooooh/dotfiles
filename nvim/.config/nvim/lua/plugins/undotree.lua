return {
  'mbbill/undotree',
  config = function()
    vim.keymap.set('n', '<leader>u', vim.cmd.UndotreeToggle, { desc = '[U]ndo on Undotree' })
    vim.g.undotree_DisabledFiletypes = { 'TelescopePrompt' }
  end,
}
