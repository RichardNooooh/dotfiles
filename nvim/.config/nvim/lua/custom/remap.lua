vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "[P]roject [V]iew Netrw" })

-- Clear highlights on search
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "Highlight when yanking (copying) text",
	group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
	callback = function()
		vim.hl.on_yank()
	end,
})
