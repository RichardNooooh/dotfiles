return {
  {
    'nvim-mini/mini.icons',
    lazy = true,
    opts = {},
    init = function()
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },
  { 'nvim-mini/mini.ai', event = 'VeryLazy', opts = { n_lines = 500 } },
  { 'nvim-mini/mini.pairs', event = 'InsertEnter', opts = {} },
  { 'folke/ts-comments.nvim', event = 'VeryLazy', opts = {} },
}
