
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "mason-org/mason.nvim",
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
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
                "lua_ls",
                "luacheck",
                "luaformatter",

                -- Python
                "ty",
                "ruff",
            }
        })
    end
}

