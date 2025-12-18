return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
		-- add cmp stuff
	},
	config = function()
		local cmp = require("cmp")
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities()
		)

		require("mason").setup()
		require("mason-lspconfig").setup()
		require("mason-tool-installer").setup({
			ensure_installed = {
				-- Docker LSP + Linter
				"docker-language-server",
				-- "docker-compose-language-service", -- ! REQUIRES npm
				"hadolint",

				-- Lua
				"stylua",
				"luacheck",

				-- Python
				"ty",
				"ruff",

				-- Go
				"gopls",

				-- OpenTofu and HCL
				"tofu-ls",
				"hclfmt",
			},
			handlers = {
				function(server_name) -- default handler (optional)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,
                -- TODO add config for stylua(?)
			},
		})
	end,
}
