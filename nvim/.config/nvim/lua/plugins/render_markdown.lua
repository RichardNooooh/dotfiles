return {
  'MeanderingProgrammer/render-markdown.nvim',
  ft = 'markdown',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },
  keys = {
    { '<leader>mr', '<cmd>RenderMarkdown buf_toggle<cr>', ft = 'markdown', desc = 'Markdown render' },
  },
  opts = { enabled = false },
}
