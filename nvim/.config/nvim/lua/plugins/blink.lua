return {
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    event = "BufReadPre",
    lazy = true,

    -- use a release tag to download pre-built binaries
    version = "1.*",
    opts = {
      keymap = { preset = "default" },
      appearance = {
        nerd_font_variant = "mono",
      },
      completion = { documentation = { auto_show = true } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      signature = { enabled = true },
      -- sources = {
      --   default = { 'avante', 'lsp', 'path', 'snippets', 'buffer' },
      --   providers = {
      --     avante = {
      --       module = 'blink-cmp-avante',
      --       name = 'Avante',
      --       opts = {
      --         -- options for blink-cmp-avante
      --       }
      --     },
      --   },
      -- },
    },
  },
}
