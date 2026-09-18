return {
  'sindrets/diffview.nvim',
  keys = {
    { "<leader>gD", "<cmd>DiffviewOpen<cr>", desc = "Open Diffview" },
    { "<leader>gX", "<cmd>DiffviewClose<cr>", desc = "Close Diffview" },
  },
  opts = {
    hooks = {
      diff_buf_win_enter = function(bufnr, winid, ctx)
        vim.wo[winid].foldenable = false
      end,
    },
  }
}
