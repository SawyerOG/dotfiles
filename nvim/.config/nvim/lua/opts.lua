local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.g.have_nerd_font = true

--  For more options, you can see `:help option-list`
-- opt.guicursor = {
--   "n-sm:block",
--   "v:hor50",
--   "c-ci-cr-i-ve:ver10",
--   "o-r:hor50",
-- }

opt.swapfile = false
opt.termguicolors = true
vim.o.pumheight = 15
vim.o.conceallevel = 0
opt.number = true
opt.relativenumber = true
opt.mouse = "v"
opt.showmode = false
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 300
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
opt.inccommand = "split"

-- Show which line your cursor is on
opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
opt.scrolloff = 10
