return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  keys = {
    {
      '<leader>/',
      function()
        require('which-key').show { global = false }
      end,
      desc = 'Buffer local keymaps',
    },
  },
  opts = {
    delay = 200,
    preset = 'modern',
    icons = { mappings = vim.g.have_nerd_font },
    spec = {
      { '<leader>g', group = 'Git' },
      { '<leader>m', group = 'Markdown' },
      { '<leader>s', group = 'Search' },
    },
  },
}
