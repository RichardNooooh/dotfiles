local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.rtp:prepend(root)

local theme = require 'custom.omarchy_theme'

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error((message or 'values differ') .. (': expected %s, got %s'):format(vim.inspect(expected), vim.inspect(actual)))
  end
end

local result = theme.from_theme_specs {
  { 'example/theme.nvim', opts = { variant = 'dark' } },
  { 'LazyVim/LazyVim', opts = { colorscheme = 'example-dark' } },
}

assert_equal(result.colorscheme, 'example-dark', 'generated colorscheme')
assert_equal(#result.specs, 1, 'LazyVim spec must be removed')
assert_equal(result.specs[1][1], 'example/theme.nvim', 'theme plugin must remain')

local fallback = theme.load '/path/that/does/not/exist/neovim.lua'
assert_equal(fallback.colorscheme, 'tokyonight-night', 'fallback colorscheme')
assert_equal(#fallback.specs, 1, 'fallback specs')
assert_equal(fallback.specs[1][1], 'folke/tokyonight.nvim', 'fallback plugin')

local configured = { opts = { colors = { bg = '#000000', fg = '#ffffff' } }, _ = { cache = { opts = {} }, loaded = {} } }
local reloaded
theme.apply_spec({ 'bjarneo/aether.nvim', name = 'aether', opts = { colors = { bg = '#ffffff' } } }, { aether = configured }, function(plugin)
  reloaded = plugin
end)
assert_equal(reloaded, configured, 'loaded theme plugin must reload')
assert_equal(configured.opts().colors.bg, '#ffffff', 'generated options must replace stale options')
assert_equal(configured.opts().colors.fg, nil, 'generated options must not retain stale nested options')
assert_equal(configured._.cache, nil, 'generated options must invalidate lazy cache')

print 'theme adapter tests passed'
