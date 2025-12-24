return {
  'folke/trouble.nvim',
  opts = {},
  cmd = 'Trouble',
  keys = {
    {
      '<leader>Td',
      '<cmd>Trouble diagnostics toggle<cr>',
      desc = 'Trouble: [T]oggle [D]iagnostics',
    },
    {
      '<leader>Tdb',
      '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
      desc = 'Trouble: [T]oggle [D]iagnostics [B]uffer',
    },
    {
      '<leader>Ts',
      '<cmd>Trouble symbols toggle focus=false<cr>',
      desc = 'Trouble: [T]oggle [S]ymbol',
    },
    {
      '<leader>Tl',
      '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',
      desc = 'Trouble: [T]oggle [L]SP Definitions / references / ...',
    },
    {
      '<leader>TL',
      '<cmd>Trouble loclist toggle<cr>',
      desc = 'Trouble: [T]oggle [L]ocation List',
    },
    {
      '<leader>Tq',
      '<cmd>Trouble qflist toggle<cr>',
      desc = 'Trouble: [T]oggle [Q]uickfix List',
    },
  },

  -- vim.keymap.set('<leader>tn', function()
  --   require('trouble').next { skip_groups = true, jump = true }
  -- end, { desc = '[T]rouble [N]ext' })
  --
  -- vim.keymap.set('<leader>tp', function()
  --   require('trouble').previous { skip_groups = true, jump = true }
  -- end, { desc = '[T]rouble [P]revious' })
}
