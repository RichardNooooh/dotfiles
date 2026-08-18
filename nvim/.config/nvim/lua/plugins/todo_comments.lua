return {
  'folke/todo-comments.nvim',
  event = 'VimEnter',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
  },
  keys = {
    { '<leader>st', '<cmd>TodoTelescope<cr>', desc = 'Todo comments' },
    { '<leader>sT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>', desc = 'Todo/Fix/Fixme' },
  },
  opts = { signs = false },
}
