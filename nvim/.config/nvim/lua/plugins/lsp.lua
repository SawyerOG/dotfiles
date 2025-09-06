return {
  -- "neovim/nvim-lspconfig",
  -- dependencies = {
  --   { "mason-org/mason.nvim", opts = {} },
  --   "mason-org/mason-lspconfig.nvim",
  --   -- "WhoIsSethDaniel/mason-tool-installer.nvim",
  --   { "j-hui/fidget.nvim", opts = {} },
  -- },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "saghen/blink.cmp",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      { "j-hui/fidget.nvim", opts = {} },
    },

    lazy = true,
    event = { "BufNewFile", "BufReadPre" },
    config = function()
      local lspconfig_defaults = require("lspconfig").util.default_config
      lspconfig_defaults.capabilities = vim.tbl_deep_extend("force", lspconfig_defaults.capabilities, require("blink.cmp").get_lsp_capabilities())
      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP actions",
        callback = function(event)
          local opts = { buffer = event.buf }

          vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
          vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
          vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
          vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
          vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
          vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
          vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
          vim.keymap.set("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "View Diagnostics" })
          vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
          vim.keymap.set({ "n", "x" }, "<leader>f", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
          vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
        end,
      })

      require("mason").setup()
      require("mason-lspconfig").setup {
        ensure_installed = {
          "vtsls",
          "gopls",
          "lua_ls",
        },
        handlers = {
          function(server_name) -- default handler (optional)
            require("lspconfig")[server_name].setup {}
          end,
          ["vtsls"] = function()
            require("lspconfig").vtsls.setup {
              root_dir = require("lspconfig").util.root_pattern(".git", "pnpm-workspace.yaml", "pnpm-lock.yaml", "yarn.lock", "package-lock.json", "bun.lockb"),
              typescript = {
                tsserver = {
                  maxTsServerMemory = 12288,
                },
              },
              experimental = {
                completion = {
                  entriesLimit = 3,
                },
              },
            }
          end,

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
          },
        },
      }
    end,

    -- lazy = true,
    -- event = { "BufNewFile", "BufReadPre" },

    -- config = function()
    --   vim.api.nvim_create_autocmd("LspAttach", {
    --     group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
    --     callback = function(event)
    --       local map = function(keys, func, desc, mode)
    --         mode = mode or "n"
    --         vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    --       end
    --       map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    --       map("<leader>a", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
    --       map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    --       -- Add more keymaps as needed
    --
    --       vim.diagnostic.config {
    --         severity_sort = true,
    --         float = { border = "rounded", source = "if_many" },
    --         underline = { severity = vim.diagnostic.severity.ERROR },
    --         signs = vim.g.have_nerd_font and {
    --           text = {
    --             [vim.diagnostic.severity.ERROR] = "󰅚 ",
    --             [vim.diagnostic.severity.WARN] = "󰀪 ",
    --             [vim.diagnostic.severity.INFO] = "󰋽 ",
    --             [vim.diagnostic.severity.HINT] = "󰌶 ",
    --           },
    --         } or {},
    --         virtual_text = {
    --           source = "if_many",
    --           spacing = 2,
    --           format = function(diagnostic)
    --             local diagnostic_message = {
    --               [vim.diagnostic.severity.ERROR] = diagnostic.message,
    --               [vim.diagnostic.severity.WARN] = diagnostic.message,
    --               [vim.diagnostic.severity.INFO] = diagnostic.message,
    --               [vim.diagnostic.severity.HINT] = diagnostic.message,
    --             }
    --             return diagnostic_message[diagnostic.severity]
    --           end,
    --         },
    --       }
    --       if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
    --         map("<leader>th", function()
    --           vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
    --         end, "[T]oggle Inlay [H]ints")
    --       end
    --     end,
    --   })
    --
    --   local capabilities = require("blink.cmp").get_lsp_capabilities()
    --   local servers = {
    --     pyright = {},
    --     gopls = {},
    --     -- ts_ls = {},
    --     vtsls = {
    --       root_dir = require("lspconfig").util.root_pattern(".git", "pnpm-workspace.yaml", "pnpm-lock.yaml", "yarn.lock", "package-lock.json", "bun.lockb"),
    --       typescript = {
    --         tsserver = {
    --           maxTsServerMemory = 12288,
    --         },
    --       },
    --       experimental = {
    --         completion = {
    --           entriesLimit = 3,
    --         },
    --       },
    --     },
    --   }
    --
    --   require("lspconfig").ruff.setup {
    --     -- disable ruff as hover provider to avoid conflicts with pyright
    --     on_attach = function(client)
    --       client.server_capabilities.hoverProvider = false
    --     end,
    --   }
    --
    --   -- local ensure_installed = vim.tbl_keys(servers or {})
    --   -- vim.list_extend(ensure_installed, {
    --   --   "stylua", -- Used to format Lua code
    --   -- })
    --   -- require("mason-tool-installer").setup { ensure_installed = ensure_installed }
    --
    --   require("mason").setup()
    --   require("mason-lspconfig").setup {
    --     ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
    --     automatic_installation = false,
    --     handlers = {
    --       function(server_name)
    --         local server = servers[server_name] or {}
    --         require("lspconfig")[server_name].setup {
    --           capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {}),
    --           settings = server.settings,
    --         }
    --       end,
    --     },
    --   }
    -- end,
  },
}
