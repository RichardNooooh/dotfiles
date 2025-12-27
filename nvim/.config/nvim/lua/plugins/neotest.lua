return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      build = function()
        vim.cmd ':TSUpdate go'
      end,
    },
    -- 'nvim-neotest/neotest-python',
    {
      'fredrikaverpil/neotest-golang',
      version = '*',
      build = function()
        vim.system({ 'go', 'install', 'gotest.tools/gotestsum@latest' }):wait()
      end,
    },
    'leoluz/nvim-dap-go',
  },
  config = function()
    require('neotest').setup {
      adapters = {
        require 'neotest-golang' {
          runner = 'gotestsum',
          -- dap = { justMyCode = false },
        },
        -- require 'neotest-python' {
        --   dap = { justMyCode = false },
        -- },
      },
    }

    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { desc = 'neotest: ' .. desc })
    end

    map('<leader>tr', function()
      require('neotest').run.run {
        suite = false,
        testify = true,
      }
    end, 'Nearest [T]est [R]un')

    map('<leader>tt', function()
      require('neotest').summary.toggle()
    end, '[T]est Summary [T]oggle')

    map('<leader>ts', function()
      require('neotest').run.run {
        suite = true,
        testify = true,
      }
    end, '[T]est [S]uite')

    map('<leader>td', function()
      require('neotest').run.run {
        suite = false,
        testify = true,
        strategy = 'dap',
      }
    end, 'Nearest [T]est [D]ebug')

    map('<leader>to', function()
      require('neotest').output.open()
    end, '[T]est [O]pen Output')

    map('<leader>ta', function()
      require('neotest').run.run(vim.fn.getcwd())
    end, '[T]est [A]ll in CWD')
  end,
}
