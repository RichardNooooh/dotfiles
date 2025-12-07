local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup()
-- REQUIRED

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = 'Harpoon [A]dd' })
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, 
    { desc = '[E]nable Harpoon window' })

vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end, { desc = 'Harpoon Get 1' })
vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end, { desc = 'Harpoon Get 2' })
vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end, { desc = 'Harpoon Get 3' })
vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end, { desc = 'Harpoon Get 4' })

