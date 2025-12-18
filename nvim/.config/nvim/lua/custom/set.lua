-- Copied from ThePrimeagen's set file

-- Line numbers and relative line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Indenting
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

-- Line wrapping
vim.opt.wrap = false

-- Perpetual history
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- '/' searching
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Colors?
vim.opt.termguicolors = true

-- Buffers top/bottom of screen with 'scrolloff' lines
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

-- Fast updates?
vim.opt.updatetime = 50

-- Color column?
-- vim.opt.colorcolumn = "80"

