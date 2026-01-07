return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    {
      "kristijanhusak/vim-dadbod-completion",
      ft = { "sql", "plsql" },
      lazy = true,
    },
  },
  cmd = {
    "DBUI",
    "DBUIToggle",
    "DBUIAddConnection",
    "DBUIFindBuffer",
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1

    vim.g.dbs = {
      local_thrive = "postgres://admin:password@localhost:5432/thrive",
      pasco_dev = "postgres://admin:password@10.91.98.6:5433/pasco_dev",

      ecco = "sqlserver://nodeuser:password@10.91.97.8:1436/ecco",
      therap = "sqlserver://nodeuser:password@10.91.97.8:1436/therap",
      ops = "sqlserver://nodeuser:password@10.91.97.8:1436/ops",
    }
  end,
  config = function()
    -- Force vim-dadbod-ui columns to 80 chars
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dbui",
      callback = function()
        -- Wrap the original render function
        local dbui = require "db_ui.view.table"
        local original_render = dbui.render_row

        dbui.render_row = function(row, col_widths, ...)
          -- Force every column width to 80
          for i = 1, #col_widths do
            col_widths[i] = 80
          end
          return original_render(row, col_widths, ...)
        end
      end,
    })
  end,
}
