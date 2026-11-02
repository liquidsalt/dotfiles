vim.pack.add({
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/nvim-telescope/telescope.nvim'
})

require('telescope').setup({
  defaults = {
    layout_config = {
      horizontal = {
        prompt_position = 'top',
      },
    },
    sorting_strategy = 'ascending',
  },
})

-- Keymaps
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').find_files, { desc = 'Find files' })
