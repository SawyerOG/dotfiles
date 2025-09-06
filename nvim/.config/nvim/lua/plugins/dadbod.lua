return {
  "kristijanhusak/vim-dadbod-ui",
  dependencies = {
    { "tpope/vim-dadbod", lazy = true },
    { "kristijanhusak/vim-dadbod-completion", ft = { "plsql", "sql" }, lazy = true },
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

      -- sqlserver = "sqlserver://nodeuser:password@10.91.97.8:1436",
    }
  end,
  config = function()
    -- Enable completion inside SQL buffers
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql", "plsql" },
      callback = function()
        local ok, cmp = pcall(require, "cmp")
        if ok then
          cmp.setup.buffer {
            sources = {
              { name = "vim-dadbod-completion" },
              { name = "buffer" },
            },
          }
        end
      end,
    })
  end,
}
