local root = assert(vim.env.NOTEBOOK_EXPERIMENT_ROOT, "NOTEBOOK_EXPERIMENT_ROOT is required")

vim.opt.runtimepath:prepend(root .. "/.local/plugins/jupynvim")
vim.g.python3_host_prog = root .. "/.local/python/bin/python"

require("jupynvim").setup({
  log_level = "info",
  auto_venv = false,
  image_renderer = "placeholder",
  image_cols = 48,
  image_rows = 10,
})
