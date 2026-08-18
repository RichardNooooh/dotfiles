vim.g.have_nerd_font = true

vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.showmode = false
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
local undodir = vim.fn.expand '~/.vim/undodir'
vim.opt.undodir = undodir
vim.fn.mkdir(undodir, 'p')
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 200
vim.opt.timeoutlen = 300
vim.opt.confirm = true
vim.opt.autowrite = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

local group = vim.api.nvim_create_augroup('custom-core', { clear = true })

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  group = group,
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

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'markdown', 'text', 'gitcommit', 'tex', 'typst' },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd('BufWritePre', {
  group = group,
  callback = function(event)
    if event.match:match '^%w%w+:[/][/]' then
      return
    end
    local directory = vim.fn.fnamemodify(event.match, ':p:h')
    if vim.fn.isdirectory(directory) == 0 then
      vim.fn.mkdir(directory, 'p')
    end
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'checkhealth', 'help', 'lspinfo', 'man', 'qf', 'startuptime' },
  callback = function(event)
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true, desc = 'Close window' })
  end,
})

vim.api.nvim_create_autocmd('VimResized', {
  group = group,
  callback = function()
    local current = vim.fn.tabpagenr()
    vim.cmd 'tabdo wincmd ='
    vim.cmd('tabnext ' .. current)
  end,
})

vim.api.nvim_create_autocmd('BufReadPre', {
  group = group,
  callback = function(event)
    local stat = vim.uv.fs_stat(event.match)
    if stat and stat.size > 2 * 1024 * 1024 then
      vim.b[event.buf].large_file = true
      vim.bo[event.buf].swapfile = false
      vim.bo[event.buf].undofile = false
    end
  end,
})
