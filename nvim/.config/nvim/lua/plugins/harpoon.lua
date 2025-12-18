return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = function()
		local harpoon = require("harpoon")

		-- REQUIRED
		harpoon:setup()
		-- REQUIRED

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end, { desc = "Harpoon [A]dd at end" })
		vim.keymap.set("n", "<leader>A", function()
			harpoon:list():prepend()
		end, { desc = "Harpoon [A]dd at head" })
		vim.keymap.set("n", "<C-e>", function()
			harpoon.ui:toggle_quick_menu(harpoon:list())
		end, { desc = "[E]nable Harpoon window" })

		-- tried the Telescope window, but I don't think I can easily move or manipulate the list
		-- with Vim motions like with the default window.
		-- TODO try make the Harpoon window look nice?

		vim.keymap.set("n", "<C-h>", function()
			harpoon:list():select(1)
		end, { desc = "Harpoon Get 1" })
		vim.keymap.set("n", "<C-j>", function()
			harpoon:list():select(2)
		end, { desc = "Harpoon Get 2" })
		vim.keymap.set("n", "<C-k>", function()
			harpoon:list():select(3)
		end, { desc = "Harpoon Get 3" })
		vim.keymap.set("n", "<C-l>", function()
			harpoon:list():select(4)
		end, { desc = "Harpoon Get 4" })
	end,
}
