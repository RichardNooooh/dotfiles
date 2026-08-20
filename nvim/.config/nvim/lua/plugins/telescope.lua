local function root()
  return vim.fs.root(0, { '.git' }) or vim.uv.cwd()
end

local function picker(name, opts)
  return function()
    require('telescope.builtin')[name](opts or {})
  end
end

return {
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  version = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    'nvim-telescope/telescope-ui-select.nvim',
    'nvim-mini/mini.icons',
  },
  keys = {
    { '<leader><leader>', picker('buffers', { sort_mru = true, sort_lastused = true }), desc = 'Find existing buffers' },
    { '<leader>s.', picker 'oldfiles', desc = 'Recent files' },
    { '<leader>sf', picker 'find_files', desc = 'Search files' },
    {
      '<leader>sg',
      function()
        require('telescope.builtin').live_grep { cwd = root() }
      end,
      desc = 'Grep root directory',
    },
    {
      '<leader>sG',
      function()
        require('telescope.builtin').live_grep()
      end,
      desc = 'Grep working directory',
    },
    { '<leader>sh', picker 'help_tags', desc = 'Help pages' },
    { '<leader>sk', picker 'keymaps', desc = 'Keymaps' },
    { '<leader>sw', picker 'grep_string', desc = 'Search word' },
    {
      '<leader>sw',
      function()
        local region = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
        require('telescope.builtin').grep_string { search = table.concat(region, ' ') }
      end,
      mode = 'x',
      desc = 'Search selection',
    },
    { '<leader>sd', picker 'diagnostics', desc = 'Diagnostics' },
    { '<leader>sD', picker('diagnostics', { bufnr = 0 }), desc = 'Buffer diagnostics' },
    { '<leader>sR', picker 'resume', desc = 'Resume picker' },
    { '<leader>ss', picker 'lsp_document_symbols', desc = 'Document symbols' },
    { '<leader>sS', picker 'lsp_dynamic_workspace_symbols', desc = 'Workspace symbols' },
    { '<leader>s"', picker 'registers', desc = 'Registers' },
    { '<leader>s/', picker 'search_history', desc = 'Search history' },
    { '<leader>sa', picker 'autocommands', desc = 'Autocommands' },
    { '<leader>sb', picker 'current_buffer_fuzzy_find', desc = 'Buffer lines' },
    { '<leader>sc', picker 'command_history', desc = 'Command history' },
    { '<leader>sC', picker 'commands', desc = 'Commands' },
    { '<leader>sH', picker 'highlights', desc = 'Highlight groups' },
    { '<leader>sj', picker 'jumplist', desc = 'Jumplist' },
    { '<leader>sl', picker 'loclist', desc = 'Location list' },
    { '<leader>sM', picker 'man_pages', desc = 'Man pages' },
    { '<leader>sm', picker 'marks', desc = 'Marks' },
    { '<leader>so', picker 'vim_options', desc = 'Options' },
    { '<leader>sq', picker 'quickfix', desc = 'Quickfix list' },
    { '<leader>gc', picker 'git_commits', desc = 'Git commits' },
    { '<leader>gl', picker 'git_commits', desc = 'Git log' },
    { '<leader>gs', picker 'git_status', desc = 'Git status' },
    { '<leader>gS', picker 'git_stash', desc = 'Git stash' },
    {
      '<leader>sn',
      function()
        require('telescope.builtin').find_files { cwd = vim.fn.stdpath 'config', follow = true }
      end,
      desc = 'Search Neovim files',
    },
  },
  opts = function()
    return {
      defaults = { prompt_prefix = '> ', selection_caret = '> ' },
      pickers = {
        find_files = { find_command = { 'rg', '--files', '--hidden', '--no-ignore', '--glob', '!**/.git/**' } },
        live_grep = { additional_args = { '--hidden', '--no-ignore', '--glob', '!**/.git/**' } },
        grep_string = { additional_args = { '--hidden', '--no-ignore', '--glob', '!**/.git/**' } },
      },
      extensions = {
        fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true, case_mode = 'smart_case' },
        ['ui-select'] = require('telescope.themes').get_dropdown(),
      },
    }
  end,
  config = function(_, opts)
    local telescope = require 'telescope'
    telescope.setup(opts)
    pcall(telescope.load_extension, 'fzf')
    pcall(telescope.load_extension, 'ui-select')
  end,
}
