return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        require('conform').format { async = true, lsp_format = 'fallback' }
      end,
      mode = '',
      desc = 'Conform: [F]ormat',
    },
  },
  opts = {
    -- notify_on_error = false,
    format_on_save = function(bufnr)
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
    end,
    formatters_by_ft = {
      lua = { 'stylua' },
      go = { 'gofmt' },
      python = { 'ruff_fix', 'ruff_format', 'ruff_organize_imports' },
      yaml = { 'yamlfmt' },
      ['yaml.ansible'] = vim.fn.executable('ansible-lint') == 1 and { 'ansible_lint' } or {},
    },
    formatters = {
      ansible_lint = {
        command = 'ansible-lint',
        args = { '--fix', '$FILENAME' },
        stdin = false,
        condition = function()
          return vim.fn.executable('ansible-lint') == 1
        end,
      },
    },
  },
}
