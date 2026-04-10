-- Copied from ThePrimeagen's set file

-- Line numbers and relative line numbers
vim.o.number = true
vim.o.relativenumber = true

-- Indenting
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.o.showmode = false -- we have mini.statusline
-- vim.o.breakindent = true

-- Mouse mode
vim.o.mouse = 'a'

-- Case-insensitive searching
vim.o.ignorecase = true
vim.o.smartcase = true

-- Line wrapping
vim.opt.wrap = false

-- Perpetual history
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'
vim.opt.undofile = true

-- '/' searching
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- Colors?
vim.opt.termguicolors = true

-- Buffers top/bottom of screen with 'scrolloff' lines
vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.isfname:append '@-@'

-- Fast updates?
vim.opt.updatetime = 50

-- Color column?
-- vim.opt.colorcolumn = "80"

vim.g.have_nerd_font = true

-- Make clipboard the same as OS clipboard
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

-- raise dialog asking to save instead of throwing errors
vim.o.confirm = true

-- initialize treesitter for everything
vim.api.nvim_create_autocmd('FileType', {
  pattern = { '*' },
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- put diagnostics on new virtual lines (v0.11 feature)
vim.diagnostic.config {
  virtual_lines = false,
}

-- Ansible filetype detection
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = {
    '*/playbooks/*.yml',
    '*/playbooks/*.yaml',
    '*/roles/*/tasks/*.yml',
    '*/roles/*/tasks/*.yaml',
    '*/roles/*/handlers/*.yml',
    '*/roles/*/handlers/*.yaml',
    '*/roles/*/defaults/*.yml',
    '*/roles/*/defaults/*.yaml',
    '*/roles/*/vars/*.yml',
    '*/roles/*/vars/*.yaml',
    '*/roles/*/meta/*.yml',
    '*/roles/*/meta/*.yaml',
    '*/group_vars/*.yml',
    '*/group_vars/*.yaml',
    '*/host_vars/*.yml',
    '*/host_vars/*.yaml',
    '*/inventory/*.yml',
    '*/inventory/*.yaml',
    'site.yml',
    'site.yaml',
  },
  callback = function()
    vim.bo.filetype = 'yaml.ansible'
  end,
})
