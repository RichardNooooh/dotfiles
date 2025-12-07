return {
    'nvim-telescope/telescope.nvim',
    tag = 'v0.2.0',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = function() 
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Telescope Find [P]roject [F]iles' })
        vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Telescope Find [P]roject Files in Git' })
        vim.keymap.set('n', '<leader>ps', function()
            builtin.grep_string({ search = vim.fn.input("Grep > ") });
        end)
        -- Currently thinking of having "p" used for "project" related things... but I don't think I like this.
        -- The examples shown in the telescope repo looks more intuitive to me right now.
    end
}
