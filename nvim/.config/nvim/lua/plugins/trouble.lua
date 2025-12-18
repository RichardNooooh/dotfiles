return {
	"folke/trouble.nvim",
	config = function()
		require("trouble").setup({
			icons = false, -- TODO consider turning on after getting nerd font?
		})

		vim.keymap.set("n", "<leader>tt", function()
			require("trouble").toggle(),
            { desc = "[T]oggle [T]rouble" }
		end)

		vim.keymap.set("n", "<leader>tn", function()
			require("trouble").next({ skip_groups = true, jump = true }),
            { desc = "[T]rouble [N]ext" }
		end)

		vim.keymap.set("n", "<leader>tp", function()
			require("trouble").previous({ skip_groups = true, jump = true })
            { desc = "[T]rouble [P]revious" }
		end)
	end
}
