return {
	"nvim-telescope/telescope.nvim",
	event = "VimEnter",
	tag = "v0.2.0",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ -- If encountering errors, see telescope-fzf-native README for installation instructions
			"nvim-telescope/telescope-fzf-native.nvim",

			-- `build` is used to run some command when the plugin is installed/updated.
			-- This is only run then, not every time Neovim starts up.
			build = "make",

			-- `cond` is a condition used to determine whether this plugin should be
			-- installed and loaded.
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		{ "nvim-telescope/telescope-ui-select.nvim" },

		-- Useful for getting pretty icons, but requires a Nerd Font.
		{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
	},
	opts = function()
		local builtin = require("telescope.builtin")

		local function map(keys, func, desc)
			vim.keymap.set("n", keys, func, { desc = "Telescope: " .. desc })
		end

		map("<leader>sh", builtin.help_tags, "[S]earch [H]elp")
		map("<leader>sk", builtin.keymaps, "[S]earch [K]eymaps")
		map("<leader>sf", builtin.find_files, "[S]earch [F]iles")
		map("<leader>ss", builtin.builtin, "[S]earch [S]elect Telescope")
		map("<leader>sw", builtin.grep_string, "[S]earch Current [W]ord")
		map("<leader>sg", builtin.live_grep, "[S]earch by [G]rep")
		map("<leader>sd", builtin.diagnostics, "[S]earch [D]iagnostics")
		map("<leader>sr", builtin.resume, "[S]earch [R]esume")
		map("<leader>s.", builtin.oldfiles, '[S]earch Recent Files ("." for repeat)')
		map("<leader><leader>", builtin.buffers, "[ ] Find Existing Buffers")
	end,
}
