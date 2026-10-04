local root = assert(vim.env.NOTEBOOK_EXPERIMENT_ROOT, "NOTEBOOK_EXPERIMENT_ROOT is required")
local plugins = root .. "/.local/plugins/"

vim.opt.runtimepath:prepend(plugins .. "image.nvim")
vim.opt.runtimepath:prepend(plugins .. "jupytext.nvim")
vim.opt.runtimepath:prepend(plugins .. "molten-nvim")
vim.opt.runtimepath:prepend(root .. "/.local/tree-sitter")
vim.g.python3_host_prog = root .. "/.local/python/bin/python"
vim.g.loaded_remote_plugins = root .. "/.local/nvim-data/nvim/rplugin.vim"
vim.cmd.source(vim.g.loaded_remote_plugins)

require("image").setup({
  backend = "kitty",
  processor = "magick_cli",
  integrations = {},
  max_width = 100,
  max_height = 12,
  max_width_window_percentage = math.huge,
  max_height_window_percentage = math.huge,
})

require("jupytext").setup({
  style = "markdown",
  output_extension = "md",
  force_ft = "markdown",
})

vim.g.molten_auto_open_output = false
vim.g.molten_image_provider = vim.env.NOTEBOOK_HEADLESS == "1" and "none" or "image.nvim"
vim.g.molten_wrap_output = true
vim.g.molten_virt_text_output = true
