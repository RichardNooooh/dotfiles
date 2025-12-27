function ColorMyPencils(color)
  vim.cmd.colorscheme(color or 'tokyonight-night')
  vim.api.nvim_set_hl(0, 'Normal', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'none' })
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#51B3EC', bold = false })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = 'white', bold = false })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#FB508F', bold = false })
end

return {
  'folke/tokyonight.nvim',
  lazy = false,
  priority = 1000,
  opts = {
    transparent = true,
    styles = {
      sidebars = 'transparent',
      floats = 'transparent',
      functions = {},
    },
    on_highlights = function(hl, _)
      -- remove the italics while keep the color
      hl['@keyword'] = vim.tbl_extend('force', hl['@keyword'] or {}, { italic = false })
      hl.Keyword = vim.tbl_extend('force', hl.Keyword or {}, { italic = false })

      local inactive_hl = '#202537'
      hl.WinSeparator = vim.tbl_extend('force', hl.WinSeparator or {}, { fg = inactive_hl })
      hl.NvimTreeWinSeparator = vim.tbl_extend('force', hl.NvimTreeWinSeparator or {}, { fg = inactive_hl })

      hl.MiniStatuslineInactive = vim.tbl_extend('force', hl.MiniStatuslineInactive or {}, { bg = inactive_hl })
    end,
  },
  config = function(_, opts)
    require('tokyonight').setup(opts) -- required since we have a config function + opts
    ColorMyPencils()
  end,
}
