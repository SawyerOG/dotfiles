return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    { "j-hui/fidget.nvim",    opts = {} },
    "saghen/blink.cmp",
  },
  event = { "BufReadPre", "BufNewFile" },

  config = function()

    vim.diagnostic.config {
      severity_sort = true,
      float = { border = "rounded", source = "if_many" },
      underline = { severity = vim.diagnostic.severity.ERROR },
      virtual_text = true,
    }

    vim.lsp.config("pyright", {
      settings = {
        python = {
          analysis = {
            typeCheckingMode = "standard",
          },
        },
      },
    })

    vim.lsp.config("tsc", {
      cmd = { "tsc", "--lsp", "--stdio" },
      filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      },
      root_markers = {
        "tsconfig.json",
        "jsconfig.json",
        "package.json",
        ".git",
      },
    })

  vim.lsp.enable({
    "gopls",
    "tsc",
    "ruff",
    "pyright"
    -- "tsgo"
    -- "vtsls"
  })

  vim.keymap.set("n", "K", function()
    vim.lsp.buf.hover({
      border = "rounded",
    })
  end, { desc = "LSP hover" })

  -- vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  --   border = 'rounded',
  --   -- Ensure syntax highlighting is enabled
  --   on_attach = function(client, bufnr)
  --     vim.api.nvim_buf_set_option(bufnr, 'filetype', client.name)
  --   end
  -- })
end
}
