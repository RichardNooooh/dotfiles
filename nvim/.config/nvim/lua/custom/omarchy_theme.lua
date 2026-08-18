local M = {}

local fallback = 'tokyonight-night'
local state_file = vim.fn.expand '~/.local/state/omarchy/current/theme/neovim.lua'
local inventory_file = '/usr/share/omarchy-nvim/config/lua/plugins/all-themes.lua'
local timer

local function fallback_theme()
  return M.from_theme_specs {
    {
      'folke/tokyonight.nvim',
      lazy = false,
      priority = 1000,
    },
    { 'LazyVim/LazyVim', opts = { colorscheme = fallback } },
  }
end

function M.from_theme_specs(theme_specs)
  local specs = {}
  local colorscheme = fallback

  for _, spec in ipairs(theme_specs or {}) do
    if spec[1] == 'LazyVim/LazyVim' then
      colorscheme = spec.opts and spec.opts.colorscheme or colorscheme
    else
      specs[#specs + 1] = spec
    end
  end

  return { specs = specs, colorscheme = colorscheme }
end

function M.load(path)
  path = path or state_file
  if vim.fn.filereadable(path) ~= 1 then
    return fallback_theme()
  end

  local ok, theme_specs = pcall(dofile, path)
  return ok and M.from_theme_specs(theme_specs) or fallback_theme()
end

function M.inventory()
  if vim.fn.filereadable(inventory_file) ~= 1 then
    return {}
  end

  local ok, specs = pcall(dofile, inventory_file)
  return ok and specs or {}
end

function M.transparent_highlights()
  local groups = {
    'Normal',
    'NormalFloat',
    'FloatBorder',
    'Pmenu',
    'Terminal',
    'EndOfBuffer',
    'FoldColumn',
    'Folded',
    'SignColumn',
    'LineNr',
    'CursorLineNr',
    'NormalNC',
    'WhichKeyFloat',
    'TelescopeBorder',
    'TelescopeNormal',
    'TelescopePromptBorder',
    'TelescopePromptTitle',
    'NeoTreeNormal',
    'NeoTreeNormalNC',
    'NeoTreeWinSeparator',
    'NeoTreeEndOfBuffer',
  }

  for _, name in ipairs(groups) do
    local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok then
      highlight.bg = nil
      vim.api.nvim_set_hl(0, name, highlight)
    end
  end
end

function M.apply_spec(spec, plugins, reload)
  local name = spec and (spec.name or spec[1]:match '/([^/]+)$')
  local plugin = name and plugins[name]
  if not plugin then
    return
  end

  -- Generated specs are the source of truth for a theme's setup options.
  local opts = vim.deepcopy(spec.opts or {})
  plugin.opts = function()
    return vim.deepcopy(opts)
  end
  plugin.opts_extend = nil
  plugin._.cache = nil
  if plugin._.loaded then
    reload(plugin)
  end
end

function M.apply(reload)
  local current = M.load()
  local loader_ok, loader = pcall(require, 'lazy.core.loader')

  if loader_ok then
    local plugins = require('lazy.core.config').plugins
    for _, spec in ipairs(current.specs) do
      M.apply_spec(spec, plugins, function(plugin)
        if reload then
          loader.reload(plugin)
        else
          loader.config(plugin)
        end
      end)
    end

    loader.colorscheme(current.colorscheme)
  end
  pcall(vim.cmd.colorscheme, current.colorscheme)
  M.transparent_highlights()
end

function M.setup()
  require('config.remote_clipboard').setup()
  local group = vim.api.nvim_create_augroup('custom-omarchy-theme', { clear = true })
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = M.transparent_highlights,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'LazyDone',
    callback = function()
      M.apply(false)
    end,
  })
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'LazyReload',
    callback = function()
      vim.schedule(function()
        M.apply(true)
      end)
    end,
  })

  if timer then
    timer:stop()
    timer:close()
  end

  if vim.fn.filereadable(state_file) == 1 then
    local function signature()
      local stat = vim.uv.fs_stat(state_file)
      return stat and table.concat({ stat.size, stat.mtime.sec, stat.mtime.nsec }, ':') or nil
    end

    local previous = signature()
    timer = vim.uv.new_timer()
    timer:start(
      2000,
      2000,
      vim.schedule_wrap(function()
        local current = signature()
        if current and previous and current ~= previous then
          M.apply(true)
        end
        previous = current
      end)
    )

    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = group,
      once = true,
      callback = function()
        if timer and not timer:is_closing() then
          timer:stop()
          timer:close()
        end
        timer = nil
      end,
    })
  end
end

return M
