vim.pack.add({
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/mikavilpas/yazi.nvim',
})

-- turn off Neovim's built-in directory browser so yazi handles directories
vim.g.loaded_netrwPlugin = 1

vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    require('yazi').setup({
      open_for_directories = true,
      floating_window_scaling_factor = 0.8,
      yazi_floating_window_border = 'rounded',
    })
  end,
})

vim.keymap.set('n', '<leader>ff', function() require('yazi').yazi() end, { desc = 'Open yazi' })
