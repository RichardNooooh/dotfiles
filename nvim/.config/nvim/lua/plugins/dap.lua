-- Adapted from tjdevries/config.nvim
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'mfussenegger/nvim-dap-python',
    'leoluz/nvim-dap-go',
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
  },
  config = function()
    local dap = require 'dap'
    local ui = require 'dapui'

    require('dapui').setup()
    require('dap-go').setup()
    require('dap-python').setup 'uv'
    require('nvim-dap-virtual-text').setup()

    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { desc = 'DAP: ' .. desc })
    end

    map('<leader>b', dap.toggle_breakpoint, 'Toggle [B]reakpoint')
    map('<leader>gb', dap.run_to_cursor, '[G]o to Cursor/[B]reakpoint')

    map('<leader>?', function()
      require('dapui').eval(nil, { enter = true })
    end, 'Evaluate var under cursor')

    map('<F1>', dap.step_back, 'Step Back')
    map('<F2>', dap.step_out, 'Step Out')
    map('<F3>', dap.step_over, 'Step Over')
    map('<F4>', dap.step_into, 'Step Into')
    map('<F5>', dap.continue, 'Continue')
    map('<F12>', dap.restart, 'Restart')

    dap.listeners.before.attach.dapui_config = function()
      ui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      ui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      ui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      ui.close()
    end

    vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
  end,
}
