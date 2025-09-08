return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "kristijanhusak/vim-dadbod-completion",
    },
    event = "BufReadPre",
    lazy = true,
    version = "1.*",
    opts = function(_, opts)
      -- preserve existing Blink options
      opts.keymap = opts.keymap or { preset = "default" }
      opts.appearance = opts.appearance or { nerd_font_variant = "mono" }
      opts.completion = opts.completion or { documentation = { auto_show = true } }
      opts.fuzzy = opts.fuzzy or { implementation = "prefer_rust_with_warning" }
      opts.signature = opts.signature or { enabled = true }

      -- ensure sources table exists
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }

      -- add Dadbod to default sources if not already present
      if not vim.tbl_contains(opts.sources.default, "dadbod") then
        table.insert(opts.sources.default, "dadbod")
      end

      -- register Dadbod as a provider
      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {
        dadbod = {
          module = "vim_dadbod_completion.blink",
          name = "Dadbod",
          min_keyword_length = 0,
        },
      })

      return opts
    end,
  },
}
