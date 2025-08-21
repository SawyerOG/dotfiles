return {
  "akinsho/bufferline.nvim",
  dependencies = {
    "moll/vim-bbye",
    "nvim-tree/nvim-web-devicons",
  },
  lazy = true,
  event = "BufReadPre", -- this will only start session saving when an actual file was opened
  keys = {
    { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>",            desc = "Toggle Pin" },
    { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
    { "<leader>br", "<Cmd>BufferLineCloseRight<CR>",           desc = "Delete Buffers to the Right" },
    { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>",            desc = "Delete Buffers to the Left" },
    { "[B",         "<cmd>BufferLineMovePrev<cr>",             desc = "Move buffer prev" },
    { "]B",         "<cmd>BufferLineMoveNext<cr>",             desc = "Move buffer next" },
  },
  opts = {
    options = {
      mode = "buffers",              -- set to "tabs" to only show tabpages instead
      themable = true,               -- allows highlight groups to be overriden i.e. sets highlights as default
      numbers = "none",              -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
      close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
      buffer_close_icon = "✗",
      close_icon = "✗",
      path_components = 1, -- Show only the file name without the directory
      modified_icon = "●",
      left_trunc_marker = "",
      right_trunc_marker = "",
      max_name_length = 30,
      max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
      tab_size = 21,
      diagnostics = "nvim_lsp",
      -- diagnostics_update_in_insert = true,
      -- diagnostics_indicator = function(count, _level, diagnostics_dict, _context)
      diagnostics_indicator = function(count)
        return "(" .. count .. ")"
      end,
      offsets = {
        {
          -- filetype = "neo-tree",
          -- text = "Neo-tree",

          filetype = "snacks_layout_box",
          text = "Snack Explorer",
          highlight = "Directory",
          text_align = "left",
        },
      },
      color_icons = true,
      show_buffer_icons = true,
      show_buffer_close_icons = true,
      show_close_icon = true,
      persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
      separator_style = { "│", "│" }, -- | "thick" | "thin" | { 'any', 'any' },
      enforce_regular_tabs = true,
      always_show_bufferline = false,
      show_tab_indicators = false,
      indicator = {
        -- icon = '▎', -- this should be omitted if indicator style is not 'icon'
        style = "underline", -- Options: 'icon', 'underline', 'none'
      },
      icon_pinned = "󰐃",
      minimum_padding = 1,
      maximum_padding = 5,
      maximum_length = 15,
      sort_by = "insert_at_end",
    },
    highlights = {
      separator = {
        fg = "#434C5E",
      },
      buffer_selected = {
        bold = true,
        italic = true,
      },
      -- tab_selected = {},
      -- background = {},
      -- indicator_selected = {},
      -- fill = {},
    },
  },
}
