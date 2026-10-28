return {
  "esmuellert/codediff.nvim",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gD", "<cmd>CodeDiff<cr>", desc = "Open CodeDiff" },
  },
  opts = {
    explorer = {
      view_mode = "tree", -- Group changed files by directory.
      line_stats = {
        enabled = true,
        count_untracked = false, -- Set to true if you want to count untracked files
        max_untracked_bytes = 1024 * 1024, -- Skip untracked files larger than 1 MB
      },
    },
  },
}
