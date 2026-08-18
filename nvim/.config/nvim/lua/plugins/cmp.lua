return {
  'saghen/blink.cmp',
  version = '1.*',
  event = { 'InsertEnter', 'CmdlineEnter' },
  dependencies = {
    'rafamadriz/friendly-snippets',
    'folke/lazydev.nvim',
  },
  opts = {
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = { draw = { treesitter = { 'lsp' } } },
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'lazydev' },
      providers = {
        lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      },
    },
    snippets = { preset = 'default' },
    signature = { enabled = true },
    fuzzy = { implementation = 'prefer_rust_with_warning' },
  },
}
