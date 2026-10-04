local servers = { 'lua_ls', 'ty', 'ruff', 'gopls', 'ols', 'ansiblels' }

local function hypr_lua_settings()
  local luarc = vim.fn.expand '~/.config/hypr/.luarc.json'
  if vim.fn.filereadable(luarc) ~= 1 or vim.fn.isdirectory '/usr/share/omarchy' ~= 1 then
    return
  end

  local ok, config = pcall(vim.json.decode, table.concat(vim.fn.readfile(luarc), '\n'))
  if not ok then
    return
  end

  local workspace = config.workspace or {}
  local library = vim.deepcopy(workspace.library or {})
  library[#library + 1] = '/usr/share/omarchy'
  return {
    workspace = vim.tbl_extend('force', workspace, { library = library }),
    diagnostics = { globals = (config.diagnostics or {}).globals or {} },
  }
end

return {
  {
    'mason-org/mason.nvim',
    cmd = 'Mason',
    opts = {},
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = {
        'lua-language-server',
        'ty',
        'ruff',
        'gopls',
        'ols',
        'ansible-language-server',
        'stylua',
        'debugpy',
      },
      auto_update = false,
      run_on_start = true,
    },
  },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'mason-org/mason.nvim',
      'saghen/blink.cmp',
      'nvim-telescope/telescope.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
    },
    config = function()
      local hypr_settings = hypr_lua_settings()
      local hypr_root = vim.fs.normalize(vim.fn.expand '~/.config/hypr')

      vim.diagnostic.config {
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = 'E ',
            [vim.diagnostic.severity.WARN] = 'W ',
            [vim.diagnostic.severity.INFO] = 'I ',
            [vim.diagnostic.severity.HINT] = 'H ',
          },
        },
        underline = true,
        virtual_text = false,
        virtual_lines = false,
        float = { border = 'rounded', source = 'if_many' },
      }

      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            completion = { callSnippet = 'Replace' },
            hint = { enable = true },
          },
        },
        before_init = function(_, config)
          local root = type(config.root_dir) == 'string' and vim.fs.normalize(config.root_dir)
          if hypr_settings and root and (root == hypr_root or vim.startswith(root, '/usr/share/omarchy/')) then
            config.settings.Lua = vim.tbl_deep_extend('force', config.settings.Lua or {}, vim.deepcopy(hypr_settings))
          end
        end,
      })
      vim.lsp.config('ty', { settings = { ty = { diagnosticMode = 'workspace' } } })
      vim.lsp.config('ruff', {
        on_attach = function(client)
          client.server_capabilities.hoverProvider = false
          client.server_capabilities.renameProvider = false
        end,
      })
      vim.lsp.config('gopls', {})
      vim.lsp.config('ols', {})
      vim.lsp.config('ansiblels', {
        filetypes = { 'yaml.ansible' },
        root_markers = { 'ansible.cfg', '.git' },
        settings = {
          ansible = {
            python = { interpreterPath = 'python3' },
            ansible = { path = 'ansible', useFullyQualifiedCollectionNames = true },
            executionEnvironment = { enabled = false },
            validation = { enabled = true, lint = { enabled = false } },
            completion = { provideRedirectModules = true, provideModuleOptionAliases = true },
          },
        },
      })

      local group = vim.api.nvim_create_augroup('custom-lsp-attach', { clear = true })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          local function map(keys, action, desc, mode)
            vim.keymap.set(mode or 'n', keys, action, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, 'Rename')
          map('gra', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
          map('grr', require('telescope.builtin').lsp_references, 'References')
          map('gri', require('telescope.builtin').lsp_implementations, 'Implementation')
          map('grd', require('telescope.builtin').lsp_definitions, 'Definition')
          map('grD', vim.lsp.buf.declaration, 'Declaration')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Document symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Workspace symbols')
          map('grt', require('telescope.builtin').lsp_type_definitions, 'Type definition')
          map('K', function()
            vim.lsp.buf.hover { border = 'rounded' }
          end, 'Hover')

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            map('<leader>th', function()
              local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, 'Toggle inlay hints')
          end

          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight = vim.api.nvim_create_augroup('custom-lsp-highlight', { clear = false })
            if not vim.b[event.buf].lsp_document_highlight then
              vim.b[event.buf].lsp_document_highlight = true
              vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                group = highlight,
                buffer = event.buf,
                callback = vim.lsp.buf.document_highlight,
              })
              vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                group = highlight,
                buffer = event.buf,
                callback = vim.lsp.buf.clear_references,
              })
            end
          end
        end,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = group,
        callback = function(event)
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(event.buf) then
              return
            end
            local supported = vim.tbl_filter(function(client)
              return client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
            end, vim.lsp.get_clients { bufnr = event.buf })
            if #supported == 0 then
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'custom-lsp-highlight', buffer = event.buf }
              vim.b[event.buf].lsp_document_highlight = nil
            end
          end)
        end,
      })

      vim.lsp.enable(servers)
    end,
  },
}
