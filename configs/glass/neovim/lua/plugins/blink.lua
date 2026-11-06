vim.pack.add({
  { src = 'https://github.com/saghen/blink.cmp', version = vim.version.range('1.*') },
})

require('blink.cmp').setup({
  keymap = {
    preset = 'none',
    ['<C-j>'] = { 'select_next', 'fallback' },
    ['<C-k>'] = { 'select_prev', 'fallback' },
    ['<Tab>'] = { 'accept', 'fallback' },
  },
  completion = {
    trigger = {
      show_on_keyword = true,            -- every letter, digit, - or _
      show_on_trigger_character = true,  -- . :: -> etc.
      show_on_backspace = true,
      show_on_insert = true,             -- as soon as you enter insert mode
    },
    documentation = { auto_show = true },
  },
  signature = { enabled = true },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
})
