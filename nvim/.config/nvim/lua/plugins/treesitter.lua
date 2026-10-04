local parsers = {
  'bash',
  'c',
  'diff',
  'go',
  'html',
  'javascript',
  'jsdoc',
  'json',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'odin',
  'printf',
  'python',
  'query',
  'regex',
  'terraform',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'xml',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    version = false,
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local treesitter = require 'nvim-treesitter'
      treesitter.setup {}

      local function installed_parsers()
        local installed = {}
        for _, parser in ipairs(treesitter.get_installed()) do
          installed[parser] = true
        end
        return installed
      end

      local function attach(bufnr)
        if vim.b[bufnr].large_file then
          return
        end
        local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
        if not lang or not installed_parsers()[lang] then
          return
        end
        pcall(vim.treesitter.start, bufnr, lang)
        if vim.bo[bufnr].filetype ~= 'python' and pcall(vim.treesitter.query.get, lang, 'indents') then
          vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
        if pcall(vim.treesitter.query.get, lang, 'folds') then
          vim.wo.foldmethod = 'expr'
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        end
      end

      local group = vim.api.nvim_create_augroup('custom-treesitter', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(event)
          attach(event.buf)
        end,
      })
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          attach(bufnr)
        end
      end

      local installed = installed_parsers()
      local missing = vim.tbl_filter(function(parser)
        return not installed[parser]
      end, parsers)
      if #missing > 0 then
        treesitter.install(missing):await(function(_, success)
          if success then
            vim.schedule(function()
              for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(bufnr) then
                  attach(bufnr)
                end
              end
              vim.api.nvim_exec_autocmds('User', { pattern = 'CustomTreesitterInstalled', modeline = false })
            end)
          end
        end)
      end
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    event = 'VeryLazy',
    opts = { move = { enable = true, set_jumps = true } },
    config = function(_, opts)
      require('nvim-treesitter-textobjects').setup(opts)
      local moves = {
        goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer', [']a'] = '@parameter.inner' },
        goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer', [']A'] = '@parameter.inner' },
        goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer', ['[a'] = '@parameter.inner' },
        goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer', ['[A'] = '@parameter.inner' },
      }

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('custom-treesitter-textobjects', { clear = true }),
        callback = function(event)
          local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
          if not lang or not pcall(vim.treesitter.query.get, lang, 'textobjects') then
            return
          end
          for method, keymaps in pairs(moves) do
            for key, query in pairs(keymaps) do
              vim.keymap.set({ 'n', 'x', 'o' }, key, function()
                require('nvim-treesitter-textobjects.move')[method](query, 'textobjects')
              end, { buffer = event.buf, desc = method:gsub('_', ' ') })
            end
          end
        end,
      })
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
          vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr, modeline = false })
        end
      end
      vim.api.nvim_create_autocmd('User', {
        pattern = 'CustomTreesitterInstalled',
        callback = function()
          for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(bufnr) then
              vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr, modeline = false })
            end
          end
        end,
      })
    end,
  },
  {
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {},
  },
}
