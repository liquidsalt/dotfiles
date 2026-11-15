vim.pack.add({
    'https://github.com/neovim/nvim-lspconfig'
})

vim.lsp.enable({
  'clangd',
  'zls',
  'rust_analyzer',
  'basedpyright', 'ruff',
  'jdtls',
  'gopls',
  'lua_ls',
  'nixd',
  'bashls',
  'qmlls',
})

-- Lua lsp extra settings
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      runtime = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
    },
  },
})

vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show error details' })
