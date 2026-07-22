local function project_root()
  return vim.fs.root(0, { '.git' }) or vim.fn.getcwd()
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  cmd = 'Neotree',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },
  keys = {
    {
      '<leader>e',
      function()
        require('neo-tree.command').execute { toggle = true, dir = project_root() }
      end,
      desc = 'Explorer (Project Root)',
    },
    {
      '<leader>E',
      function()
        require('neo-tree.command').execute { toggle = true, dir = vim.fn.getcwd() }
      end,
      desc = 'Explorer (cwd)',
    },
  },
  opts = {
    window = {
      position = 'left',
      mappings = {
        l = 'open',
        h = 'close_node',
        ['<space>'] = 'none',
      },
    },
    filesystem = {
      bind_to_cwd = false,
      filtered_items = {
        hide_dotfiles = false,
        always_show_by_pattern = { '.*' },
      },
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      hijack_netrw_behavior = 'disabled',
    },
  },
}
