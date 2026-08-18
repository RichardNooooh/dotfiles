return {
  'nvim-lualine/lualine.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-mini/mini.icons' },
  opts = function()
    local function lsp_clients()
      local names = {}
      for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
        names[#names + 1] = client.name
      end
      return table.concat(names, ', ')
    end

    return {
      options = {
        theme = 'auto',
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = { statusline = { 'dashboard', 'snacks_dashboard' } },
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { lsp_clients, 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    }
  end,
}
