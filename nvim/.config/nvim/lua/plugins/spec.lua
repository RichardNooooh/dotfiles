
return {
    { 
        'nvim-telescope/telescope.nvim', tag = 'v0.2.0',
          dependencies = { 'nvim-lua/plenary.nvim' }
    },

--    {
--        'nvim-treesitter/nvim-treesitter', lazy = false,
--          branch = 'main', build = ':TSUpdate'
--    },
    {
        "nvim-treesitter/nvim-treesitter", branch = 'master', 
	 lazy = false, build = ":TSUpdate"
    },
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" }
    }
}

