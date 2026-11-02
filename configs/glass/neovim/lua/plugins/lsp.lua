vim.pack.add({
    'https://github.com/neovim/nvim-lspconfig'
})

vim.lsp.enable({
  'clangd',
  'rust_analyzer',
  'basedpyright',
  'ruff',
  'jdtls',
  'gopls',
  'lua_ls',
  'nixd',
  'bashls',
  'fish_lsp',
  'qmlls',
  'hyprls',
  'marksman',
  'taplo',
  'yamlls',
  'jsonls',
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
