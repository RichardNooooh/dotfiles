return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>f',
      function()
        local policy = require 'custom.format'
        local context = policy.context(vim.api.nvim_get_current_buf())
        local formatters = context and policy.manual_formatters(context) or {}
        if #formatters > 0 then
          require('conform').format { async = true, formatters = formatters, lsp_format = 'never' }
        end
      end,
      mode = { 'n', 'x' },
      desc = 'Conform: [F]ormat',
    },
  },
  opts = {
    -- notify_on_error = false,
    format_on_save = function(bufnr)
      local policy = require 'custom.format'
      local context = policy.context(bufnr)
      local formatters = context and policy.save_formatters(context) or {}
      if #formatters > 0 then
        return {
          timeout_ms = 500,
          formatters = formatters,
          lsp_format = 'never',
        }
      end
    end,
    formatters = {
      prettier = {
        prefer_local = 'node_modules/.bin',
      },
      ruff_fix = { prefer_local = '.venv/bin' },
      ruff_format = { prefer_local = '.venv/bin' },
      ruff_organize_imports = { prefer_local = '.venv/bin' },
      sqlfluff = { prefer_local = '.venv/bin' },
      ansible_lint = {
        command = 'ansible-lint',
        args = { '--fix', '$FILENAME' },
        stdin = false,
        prefer_local = '.venv/bin',
      },
    },
  },
}
