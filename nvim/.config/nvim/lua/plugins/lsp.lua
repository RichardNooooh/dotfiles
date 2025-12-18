return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		-- add cmp stuff
	},
	config = function()
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
		})
	end,
}
