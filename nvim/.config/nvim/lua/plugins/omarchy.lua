local theme = require 'custom.omarchy_theme'
local current = theme.load()
local specs = theme.inventory()

vim.list_extend(specs, current.specs)
specs[#specs + 1] = {
  name = 'omarchy-theme',
  dir = vim.fn.stdpath 'config',
  lazy = false,
  priority = 1000,
  config = theme.setup,
}

return specs
