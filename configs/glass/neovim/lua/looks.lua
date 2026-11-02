-- Line Numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Tabs as Spaces
vim.opt.expandtab = true   -- Tab inserts spaces instead of a tab character
vim.opt.tabstop = 4        -- a tab character displays as 4 columns wide
vim.opt.shiftwidth = 4     -- >>, << and auto-indent move by 4 spaces
vim.opt.softtabstop = 4    -- Tab and Backspace move by 4 spaces

-- Disable Neovim Bg
local function use_terminal_bg()
  for _, group in ipairs({ 'Normal', 'NormalNC', 'NormalFloat', 'SignColumn', 'LineNr', 'FoldColumn' }) do
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    hl.bg = nil
    vim.api.nvim_set_hl(0, group, hl)
  end
end
use_terminal_bg()
vim.api.nvim_create_autocmd('ColorScheme', { callback = use_terminal_bg }) -- re-apply whenever a colorscheme is loaded
