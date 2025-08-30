require "opts"
require "keymaps"
require "functions.floaterm"

--  See `:help lua-guide-autocommands`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup {
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
  {
    "neanias/everforest-nvim",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    -- Optional; default configuration will be used if setup isn't called.
    config = function()
      require("everforest").setup {
        backgroung = "hard",
      }
      require("everforest").load()
    end,
  },
  -- {
  --   "ribru17/bamboo.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("bamboo").setup {
  --       -- optional configuration here
  --     }
  --     require("bamboo").load()
  --   end,
  -- },

  require "plugins.debug",
  -- require "plugins.indent_line",
  require "plugins.lint",
  -- require "plugins.autopairs",
  -- require "plugins.neo-tree",
  require "plugins.gitsigns",
  require "plugins.whichkey",
  -- require "plugins.telescope",
  require "plugins.lsp",
  require "plugins.treesitter",
  -- require "plugins.autocompletion",
  require "plugins.blink",
  require "plugins.autoformat",
  require "plugins.mini",
  require "plugins.lualine",
  require "plugins.neotest",
  require "plugins.bufferline",
  require "plugins.rainbow-delim",
  require "plugins.flash",
  require "plugins.autotag",
  require "plugins.snacks",
  -- require "plugins.avante",
  -- require "plugins.trouble",
  -- require "plugins.noice",
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
