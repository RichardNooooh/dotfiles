return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'mfussenegger/nvim-dap-python',
    'rcarriga/nvim-dap-ui',
    'theHamsta/nvim-dap-virtual-text',
    'nvim-neotest/nvim-nio',
    'mason-org/mason.nvim',
  },
  config = function()
    local dap = require 'dap'
    local ui = require 'dapui'
    local adapter = vim.fn.stdpath 'data' .. '/mason/bin/debugpy-adapter'

    require('dap-python').setup(adapter)
    ui.setup {
      layouts = {
        {
          position = 'left',
          size = 60,
          elements = {
            { id = 'scopes', size = 0.4 },
            { id = 'breakpoints', size = 0.2 },
            { id = 'stacks', size = 0.2 },
            { id = 'watches', size = 0.2 },
          },
        },
        {
          position = 'bottom',
          size = 15,
          elements = {
            { id = 'repl', size = 0.4 },
            { id = 'console', size = 0.6 },
          },
        },
      },
    }
    require('nvim-dap-virtual-text').setup()

    local function map(keys, action, desc, mode)
      vim.keymap.set(mode or 'n', keys, action, { desc = 'DAP: ' .. desc })
    end

    map('<leader>b', dap.toggle_breakpoint, 'Toggle breakpoint')
    map('<leader>gb', dap.run_to_cursor, 'Run to cursor')
    map('<leader>?', function()
      ui.eval(nil, { enter = true })
    end, 'Evaluate under cursor', { 'n', 'x' })
    map('<F2>', dap.step_out, 'Step out')
    map('<F3>', dap.step_over, 'Step over')
    map('<F4>', dap.step_into, 'Step into')
    map('<F5>', dap.continue, 'Continue')
    map('<F12>', dap.restart, 'Restart')

    dap.listeners.before.attach.custom_dapui = ui.open
    dap.listeners.before.launch.custom_dapui = ui.open
    dap.listeners.before.event_terminated.custom_dapui = ui.close
    dap.listeners.before.event_exited.custom_dapui = ui.close

    vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
  end,
}
