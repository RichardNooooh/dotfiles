return {
  'kdheepak/lazygit.nvim',
  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    { '<leader>gg', '<cmd>LazyGit<CR>', desc = '[G]it [G]it UI' },
    { '<leader>gf', '<cmd>LazyGitCurrentFile<CR>', desc = '[G]it Current [F]ile' },
    { '<leader>gF', '<cmd>LazyGitFilterCurrentFile<CR>', desc = '[G]it [F]ile History' },
  },
}
