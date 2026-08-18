return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  opts = {
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'
      local function map(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = 'Git: ' .. desc })
      end

      map('n', ']h', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, 'Next hunk')
      map('n', '[h', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, 'Previous hunk')
      map({ 'n', 'x' }, '<leader>ghs', gitsigns.stage_hunk, 'Stage hunk')
      map({ 'n', 'x' }, '<leader>ghr', gitsigns.reset_hunk, 'Reset hunk')
      map('n', '<leader>ghS', gitsigns.stage_buffer, 'Stage buffer')
      map('n', '<leader>ghu', gitsigns.undo_stage_hunk, 'Undo stage hunk')
      map('n', '<leader>ghp', gitsigns.preview_hunk_inline, 'Preview hunk')
      map('n', '<leader>ghb', function()
        gitsigns.blame_line { full = true }
      end, 'Blame line')
      map('n', '<leader>ghB', gitsigns.blame, 'Blame buffer')
      map('n', '<leader>ghd', gitsigns.diffthis, 'Diff against index')
      map('n', '<leader>ghD', function()
        gitsigns.diffthis '~'
      end, 'Diff against last commit')
    end,
  },
}
