return {
  "emrearmagan/atlas.nvim",
  -- Only load when the :Atlas command is first used.
  cmd = "Atlas",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- optional but recommended
    "esmuellert/codediff.nvim",
  },
  ---@type AtlasConfig
  opts = {
    ui = {
      -- Set either to false to keep your existing statusline.
      statusline = {
        atlas = true, -- Dashboards, details, and other non-diff Atlas views.
        diff = true, -- Diff and review views.
      },
      -- "auto", "default", "snacks", or "fzf-lua".
      picker = "auto",
      -- Make the main Atlas dashboard a listed buffer.
      listed_buffer = false,
    },

    -- Only providers listed here are enabled.
    providers = {
      ---@type AtlasGitHubConfig
      github = {
        -- hostname = "github.company.com", -- Defaults to GH_HOST, then github.com.
        cache_ttl = 300, -- Set to 0 to disable caching.
      },
    },

    pulls = {
      diff = { open_cmd = "CodeDiff" },
    },
    issues = {},
  },
}
