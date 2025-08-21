return {
  "neovim/nvim-lspconfig",
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    -- Mason must be loaded before its dependents so we need to set it up here.
    -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
    { "mason-org/mason.nvim", opts = {} },
    "mason-org/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",

    -- Useful status updates for LSP.
    { "j-hui/fidget.nvim", opts = {} },

    -- Allows extra capabilities provided by blink.cmp
    "saghen/blink.cmp",
  },

  -- event = "BufNew", -- this will only start session saving when an actual file was opened

  event = { "BufNewFile", "BufReadPre" },

  config = function()
    -- Defer blink.cmp setup until first insert mode
    -- vim.api.nvim_create_autocmd("InsertEnter", {
    --   once = true,
    --   callback = function()
    --     require("blink.cmp").setup()
    --   end,
    -- })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end
        map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("<leader>a", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        -- Add more keymaps as needed

        vim.diagnostic.config {
          severity_sort = true,
          float = { border = "rounded", source = "if_many" },
          underline = { severity = vim.diagnostic.severity.ERROR },
          signs = vim.g.have_nerd_font and {
            text = {
              [vim.diagnostic.severity.ERROR] = "󰅚 ",
              [vim.diagnostic.severity.WARN] = "󰀪 ",
              [vim.diagnostic.severity.INFO] = "󰋽 ",
              [vim.diagnostic.severity.HINT] = "󰌶 ",
            },
          } or {},
          virtual_text = {
            source = "if_many",
            spacing = 2,
            format = function(diagnostic)
              local diagnostic_message = {
                [vim.diagnostic.severity.ERROR] = diagnostic.message,
                [vim.diagnostic.severity.WARN] = diagnostic.message,
                [vim.diagnostic.severity.INFO] = diagnostic.message,
                [vim.diagnostic.severity.HINT] = diagnostic.message,
              }
              return diagnostic_message[diagnostic.severity]
            end,
          },
        }
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, "[T]oggle Inlay [H]ints")
        end
      end,
    })

    local capabilities = require("blink.cmp").get_lsp_capabilities()
    local servers = {
      pyright = {},
      gopls = {},
      ts_ls = {},
      -- pylsp = {
      --   settings = {
      --     pylsp = {
      --       configSources = {},
      --       plugins = {
      --         pyflakes = { enabled = false },
      --         pycodestyle = { enabled = false },
      --         autopep8 = { enabled = false },
      --         yapf = { enabled = false },
      --         mccabe = { enabled = false },
      --         mypy = { enabled = false },
      --         black = { enabled = false },
      --         isort = { enabled = false },
      --         ruff = { enabled = true },
      --       },
      --     },
      --   },
      --   -- capabilities = capabilities,
      -- },
    }

    require("lspconfig").ruff.setup {
      -- disable ruff as hover provider to avoid conflicts with pyright
      on_attach = function(client)
        client.server_capabilities.hoverProvider = false
      end,
    }

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      "stylua", -- Used to format Lua code
    })
    require("mason-tool-installer").setup { ensure_installed = ensure_installed }

    require("mason-lspconfig").setup {
      ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
      automatic_installation = false,
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          require("lspconfig")[server_name].setup {
            capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {}),
            settings = server.settings,
          }
        end,
      },
      -- handlers = {
      --   function(server_name)
      --     local server = servers[server_name] or {}
      --     -- This handles overriding only values explicitly passed
      --     -- by the server configuration above. Useful when disabling
      --     -- certain features of an LSP (for example, turning off formatting for ts_ls)
      --     server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
      --     require("lspconfig")[server_name].setup(server)
      --   end,
      -- },
    }
  end,
}
