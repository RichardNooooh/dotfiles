function ColorMyPencils(color)
	vim.cmd.colorscheme(color or "tokyonight-night")
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
	"folke/tokyonight.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		transparent = true,
		styles = {
			sidebars = "transparent",
			floats = "transparent",
			functions = {},
		},
		on_highlights = function(hl, c)
			-- remove the highlights while keep the color
			hl["@keyword"] = vim.tbl_extend("force", hl["@keyword"] or {}, { italic = false })
		end,
	},
	config = function(_, opts)
		require("tokyonight").setup(opts) -- required since we have a config function + opts
		ColorMyPencils()
	end,
}
