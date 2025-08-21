-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim
--
vim.api.nvim_create_autocmd('BufLeave', {
  group = vim.api.nvim_create_augroup('NeoTreeAutoRefresh', { clear = true }),
  callback = function()
    -- Check if Neo-tree is open in the current window
    local neo_tree_buf = vim.fn.bufnr 'neo-tree filesystem'
    local current_buf = vim.api.nvim_get_current_buf()
    local winid = vim.fn.bufwinid(neo_tree_buf)

    if winid ~= -1 and neo_tree_buf ~= current_buf then
      local state = require('neo-tree.sources.manager').get_state 'filesystem'
      require('neo-tree.sources.filesystem.commands').refresh(state)
    end
  end,
  desc = 'Refresh Neo-tree on buffer change',
})

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '<leader>e', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
      },
      window = {
        mappings = {
          ['<leader>e'] = 'close_window',
        },
      },

      components = {
        isActive = function(config, node, _)
          local indicator = ''
          local path = node:get_id()
          local active_buffer = vim.api.nvim_get_current_buf()
          local node_buffer = vim.fn.bufnr(path)

          if node_buffer == active_buffer then
            indicator = '***'

            return {
              -- text = string.format("%d ", indicator)
              text = indicator,
              highlight = config.highlight or 'NeoTreeDirectoryIcon',
            }
          end

          return {
            text = indicator,
          }
        end,
      },
      renderers = {
        file = {
          { 'icon' },
          { 'name', use_git_status_colors = true },
          { 'diagnostics' },
          { 'git_status', highlight = 'NeoTreeDimText' },
          { 'isActive' },
        },
      },
    },
  },
}
