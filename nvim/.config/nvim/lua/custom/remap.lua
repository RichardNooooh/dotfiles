vim.keymap.set('n', '<leader>pv', vim.cmd.Ex, { desc = '[P]roject [V]iew Netrw' })

-- Clear highlights on search
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- modify page movement (thanks Prime)
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')

-- "greatest remap ever" to keep my paste register
vim.keymap.set('x', '<leader>p', [["_dP]])

vim.keymap.set('n', '<M-j>', '<cmd>move .+1<cr>==', { desc = 'Move line down' })
vim.keymap.set('n', '<M-k>', '<cmd>move .-2<cr>==', { desc = 'Move line up' })
vim.keymap.set('x', '<M-j>', ":move '>+1<cr>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('x', '<M-k>', ":move '<-2<cr>gv=gv", { desc = 'Move selection up' })
