return {
  -- Main LSP Configuration
  "neovim/nvim-lspconfig",
  dependencies = {
    { "mason-org/mason.nvim", opts = {} },
    { "j-hui/fidget.nvim", opts = {} },
    "saghen/blink.cmp",
  },

  lazy = true,
  event = { "BufNewFile", "BufReadPre" },
  config = function()
    -- Implementation of misc.findup
    local misc = {}
    function misc.findup(fname, patterns)
      local path = require("lspconfig.util").path
      local root = path.dirname(fname)
      while root and root ~= path.dirname(root) do
        for _, pattern in ipairs(patterns) do
          if path.exists(path.join(root, pattern)) then
            return root
          end
        end
        root = path.dirname(root)
      end
      for _, pattern in ipairs(patterns) do
        if path.exists(path.join(root, pattern)) then
          return root
        end
      end
      return nil
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end
        map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
        map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
        map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        ---@param client vim.lsp.Client
        ---@param method vim.lsp.protocol.Method
        ---@param bufnr? integer
        local function client_supports_method(client, method, bufnr)
          if vim.fn.has "nvim-0.11" == 1 then
            return client:supports_method(method, bufnr)
          else
            return client.supports_method(method, { bufnr = bufnr })
          end
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
            end,
          })
        end
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, "[T]oggle Inlay [H]ints")
        end
      end,
    })

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

    local capabilities = require("blink.cmp").get_lsp_capabilities()
    local lspconfig = require "lspconfig"

    -- Directly configure LSP servers
    lspconfig.gopls.setup {
      capabilities = capabilities,
      settings = {},
    }

    lspconfig.vtsls.setup {
      capabilities = capabilities,
      root_dir = function(fname)
        local node = misc.findup(fname, { "package.json", "node_modules" })
        if node then
          local deno = misc.findup(fname, { "deno.json" })
          if not deno or #deno > #node then
            return node
          end
        end
        return nil
      end,
      single_file_support = false,
      settings = {
        javascript = {
          suggest = {
            names = false,
            completeFunctionCalls = true,
          },
        },
        typescript = {
          suggest = {
            names = false,
            completeFunctionCalls = true,
          },
          preferences = {
            names = false,
          },
        },
      },
    }

    lspconfig.denols.setup {
      capabilities = capabilities,
      root_dir = function(fname)
        local deno = misc.findup(fname, { "deno.json" })
        local node = misc.findup(fname, { "package.json", "node_modules" })
        if deno then
          if not node or #node > #deno then
            return deno
          end
        end
        if node then
          return nil
        end
        return vim.fs.dirname(fname)
      end,
      single_file_support = false,
      filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact", "markdown" },
      settings = {
        deno = {
          enable = true,
          unstable = false,
          suggest = {
            imports = {
              hosts = {
                ["https://deno.land"] = true,
              },
            },
          },
          lint = true,
          codeLens = {
            implementations = true,
            references = true,
          },
        },
      },
    }

    lspconfig.lua_ls.setup {
      capabilities = capabilities,
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          diagnostics = { disable = { "missing-fields" } },
        },
      },
    }

    lspconfig.ruff.setup {
      on_attach = function(client)
        client.server_capabilities.documentFormattingProvider = true
      end,
      before_init = function(_, config)
        config.offset_encoding = "utf-16" -- force UTF-16 for Ruff
      end,
    }

    -- Pyright LSP
    lspconfig.pyright.setup {
      before_init = function(_, config)
        config.offset_encoding = "utf-16" -- ensure UTF-16
      end,
    }

    -- Configure Mason to install tools
    require("mason").setup()
    -- local ensure_installed = { "gopls", "vtsls", "deno", "lua_ls", "stylua" }
    -- -- Manual installation check (since mason-lspconfig is removed)
    -- for _, tool in ipairs(ensure_installed) do
    --   local p = require("mason-registry").get_package(tool)
    --   if not p:is_installed() then
    --     p:install()
    --   end
    -- end
  end,
}

-- return {
--   -- Main LSP Configuration
--   "neovim/nvim-lspconfig",
--   dependencies = {
--     -- Automatically install LSPs and related tools to stdpath for Neovim
--     -- Mason must be loaded before its dependents so we need to set it up here.
--     -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
--     { "mason-org/mason.nvim", opts = {} },
--     "mason-org/mason-lspconfig.nvim",
--     "WhoIsSethDaniel/mason-tool-installer.nvim",
--
--     -- Useful status updates for LSP.
--     { "j-hui/fidget.nvim", opts = {} },
--
--     -- Allows extra capabilities provided by blink.cmp
--     "saghen/blink.cmp",
--   },
--   config = function()
--     -- Brief aside: **What is LSP?**
--     --
--     -- LSP is an initialism you've probably heard, but might not understand what it is.
--     --
--     -- LSP stands for Language Server Protocol. It's a protocol that helps editors
--     -- and language tooling communicate in a standardized fashion.
--     --
--     -- In general, you have a "server" which is some tool built to understand a particular
--     -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
--     -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
--     -- processes that communicate with some "client" - in this case, Neovim!
--     --
--     -- LSP provides Neovim with features like:
--     --  - Go to definition
--     --  - Find references
--     --  - Autocompletion
--     --  - Symbol Search
--     --  - and more!
--     --
--     -- Thus, Language Servers are external tools that must be installed separately from
--     -- Neovim. This is where `mason` and related plugins come into play.
--     --
--     -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
--     -- and elegantly composed help section, `:help lsp-vs-treesitter`
--
--     --  This function gets run when an LSP attaches to a particular buffer.
--     --    That is to say, every time a new file is opened that is associated with
--     --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--     --    function will be executed to configure the current buffer
--     vim.api.nvim_create_autocmd("LspAttach", {
--       group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
--       callback = function(event)
--         -- NOTE: Remember that Lua is a real programming language, and as such it is possible
--         -- to define small helper and utility functions so you don't have to repeat yourself.
--         --
--         -- In this case, we create a function that lets us more easily define mappings specific
--         -- for LSP related items. It sets the mode, buffer and description for us each time.
--         local map = function(keys, func, desc, mode)
--           mode = mode or "n"
--           vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
--         end
--
--         -- Rename the variable under your cursor.
--         --  Most Language Servers support renaming across files, etc.
--         map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
--
--         -- Execute a code action, usually your cursor needs to be on top of an error
--         -- or a suggestion from your LSP for this to activate.
--         map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
--
--         -- Find references for the word under your cursor.
--         -- map("grr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
--         --
--         -- -- Jump to the implementation of the word under your cursor.
--         -- --  Useful when your language has ways of declaring types without an actual implementation.
--         -- map("gri", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
--         --
--         -- -- Jump to the definition of the word under your cursor.
--         -- --  This is where a variable was first declared, or where a function is defined, etc.
--         -- --  To jump back, press <C-t>.
--         -- map("grd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
--
--         -- WARN: This is not Goto Definition, this is Goto Declaration.
--         --  For example, in C this would take you to the header.
--         map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
--
--         -- Fuzzy find all the symbols in your current document.
--         --  Symbols are things like variables, functions, types, etc.
--         -- map("gO", require("telescope.builtin").lsp_document_symbols, "Open Document Symbols")
--         --
--         -- -- Fuzzy find all the symbols in your current workspace.
--         -- --  Similar to document symbols, except searches over your entire project.
--         -- map("gW", require("telescope.builtin").lsp_dynamic_workspace_symbols, "Open Workspace Symbols")
--         --
--         -- -- Jump to the type of the word under your cursor.
--         -- --  Useful when you're not sure what type a variable is and you want to see
--         -- --  the definition of its *type*, not where it was *defined*.
--         -- map("grt", require("telescope.builtin").lsp_type_definitions, "[G]oto [T]ype Definition")
--
--         -- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
--         ---@param client vim.lsp.Client
--         ---@param method vim.lsp.protocol.Method
--         ---@param bufnr? integer some lsp support methods only in specific files
--         ---@return boolean
--         local function client_supports_method(client, method, bufnr)
--           if vim.fn.has "nvim-0.11" == 1 then
--             return client:supports_method(method, bufnr)
--           else
--             return client.supports_method(method, { bufnr = bufnr })
--           end
--         end
--
--         -- The following two autocommands are used to highlight references of the
--         -- word under your cursor when your cursor rests there for a little while.
--         --    See `:help CursorHold` for information about when this is executed
--         --
--         -- When you move your cursor, the highlights will be cleared (the second autocommand).
--         local client = vim.lsp.get_client_by_id(event.data.client_id)
--         if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
--           local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
--           vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
--             buffer = event.buf,
--             group = highlight_augroup,
--             callback = vim.lsp.buf.document_highlight,
--           })
--
--           vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
--             buffer = event.buf,
--             group = highlight_augroup,
--             callback = vim.lsp.buf.clear_references,
--           })
--
--           vim.api.nvim_create_autocmd("LspDetach", {
--             group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
--             callback = function(event2)
--               vim.lsp.buf.clear_references()
--               vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
--             end,
--           })
--         end
--
--         -- The following code creates a keymap to toggle inlay hints in your
--         -- code, if the language server you are using supports them
--         --
--         -- This may be unwanted, since they displace some of your code
--         if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
--           map("<leader>th", function()
--             vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
--           end, "[T]oggle Inlay [H]ints")
--         end
--       end,
--     })
--
--     -- Diagnostic Config
--     -- See :help vim.diagnostic.Opts
--     vim.diagnostic.config {
--       severity_sort = true,
--       float = { border = "rounded", source = "if_many" },
--       underline = { severity = vim.diagnostic.severity.ERROR },
--       signs = vim.g.have_nerd_font and {
--         text = {
--           [vim.diagnostic.severity.ERROR] = "󰅚 ",
--           [vim.diagnostic.severity.WARN] = "󰀪 ",
--           [vim.diagnostic.severity.INFO] = "󰋽 ",
--           [vim.diagnostic.severity.HINT] = "󰌶 ",
--         },
--       } or {},
--       virtual_text = {
--         source = "if_many",
--         spacing = 2,
--         format = function(diagnostic)
--           local diagnostic_message = {
--             [vim.diagnostic.severity.ERROR] = diagnostic.message,
--             [vim.diagnostic.severity.WARN] = diagnostic.message,
--             [vim.diagnostic.severity.INFO] = diagnostic.message,
--             [vim.diagnostic.severity.HINT] = diagnostic.message,
--           }
--           return diagnostic_message[diagnostic.severity]
--         end,
--       },
--     }
--
--     -- LSP servers and clients are able to communicate to each other what features they support.
--     --  By default, Neovim doesn't support everything that is in the LSP specification.
--     --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
--     --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
--     local capabilities = require("blink.cmp").get_lsp_capabilities()
--
--     -- Enable the following language servers
--     --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--     --
--     --  Add any additional override configuration in the following tables. Available keys are:
--     --  - cmd (table): Override the default command used to start the server
--     --  - filetypes (table): Override the default list of associated filetypes for the server
--     --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
--     --  - settings (table): Override the default settings passed when initializing the server.
--     --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
--     local servers = {
--       -- clangd = {},
--       gopls = {},
--       vtsls = {
--         root_dir = require("lspconfig").util.root_pattern { "package.json", "tsconfig.json" },
--         single_file_support = false,
--         settings = {},
--       },
--       denols = {
--         root_dir = require("lspconfig").util.root_pattern { "deno.json", "deno.jsonc" },
--         single_file_support = false,
--         settings = {},
--       },
--       -- pyright = {},
--       -- rust_analyzer = {},
--       -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
--       --
--       -- Some languages (like typescript) have entire language plugins that can be useful:
--       --    https://github.com/pmizio/typescript-tools.nvim
--       --
--       -- But for many setups, the LSP (`ts_ls`) will work just fine
--       -- ts_ls = {},
--       --
--
--       lua_ls = {
--         -- cmd = { ... },
--         -- filetypes = { ... },
--         -- capabilities = {},
--         settings = {
--           Lua = {
--             completion = {
--               callSnippet = "Replace",
--             },
--             -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
--             diagnostics = { disable = { "missing-fields" } },
--           },
--         },
--       },
--     }
--
--     -- Ensure the servers and tools above are installed
--     --
--     -- To check the current status of installed tools and/or manually install
--     -- other tools, you can run
--     --    :Mason
--     --
--     -- You can press `g?` for help in this menu.
--     --
--     -- `mason` had to be setup earlier: to configure its options see the
--     -- `dependencies` table for `nvim-lspconfig` above.
--     --
--     -- You can add other tools here that you want Mason to install
--     -- for you, so that they are available from within Neovim.
--     local ensure_installed = vim.tbl_keys(servers or {})
--     vim.list_extend(ensure_installed, {
--       "stylua", -- Used to format Lua code
--     })
--     -- require("mason-tool-installer").setup { ensure_installed = ensure_installed }
--
--     require("mason-lspconfig").setup {
--       ensure_installed = {}, -- explicitly set to an empty table
--       automatic_installation = false,
--       handlers = {
--         function(server_name)
--           local server = servers[server_name] or {}
--           -- Merge capabilities
--           server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
--           require("lspconfig")[server_name].setup(server)
--         end,
--       },
--     }
--   end,
-- }

-- return {
--   {
--     "neovim/nvim-lspconfig",
--     dependencies = {
--       "saghen/blink.cmp",
--       "williamboman/mason.nvim",
--       "williamboman/mason-lspconfig.nvim",
--       { "j-hui/fidget.nvim", opts = {} },
--     },
--
--     lazy = true,
--     event = { "BufNewFile", "BufReadPre" },
--     config = function()
--       local lspconfig_defaults = require("lspconfig").util.default_config
--       lspconfig_defaults.capabilities = vim.tbl_deep_extend("force", lspconfig_defaults.capabilities, require("blink.cmp").get_lsp_capabilities())
--       vim.api.nvim_create_autocmd("LspAttach", {
--         desc = "LSP actions",
--         callback = function(event)
--           local opts = { buffer = event.buf }
--
--           vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
--           vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
--           vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
--           vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
--           vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
--           vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
--           vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
--           vim.keymap.set("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<cr>", { desc = "View Diagnostics" })
--           vim.keymap.set("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
--           vim.keymap.set({ "n", "x" }, "<leader>f", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
--           vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
--
--           local client = vim.lsp.get_client_by_id(event.data.client_id)
--           local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
--           vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
--             buffer = event.buf,
--             group = highlight_augroup,
--             callback = vim.lsp.buf.document_highlight,
--           })
--
--           vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
--             buffer = event.buf,
--             group = highlight_augroup,
--             callback = vim.lsp.buf.clear_references,
--           })
--
--           vim.api.nvim_create_autocmd("LspDetach", {
--             group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
--             callback = function(event2)
--               vim.lsp.buf.clear_references()
--               vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
--             end,
--           })
--
--           vim.diagnostic.config {
--             severity_sort = true,
--             float = { border = "rounded", source = "if_many" },
--             underline = true,
--             signs = vim.g.have_nerd_font and {
--               text = {
--                 [vim.diagnostic.severity.ERROR] = "󰅚 ",
--                 [vim.diagnostic.severity.WARN] = "󰀪 ",
--                 [vim.diagnostic.severity.INFO] = "󰋽 ",
--                 [vim.diagnostic.severity.HINT] = "󰌶 ",
--               },
--             } or {},
--             virtual_text = {
--               source = "if_many",
--               spacing = 2,
--               wrap = true,
--               format = function(diagnostic)
--                 local diagnostic_message = {
--                   [vim.diagnostic.severity.ERROR] = diagnostic.message,
--                   [vim.diagnostic.severity.WARN] = diagnostic.message,
--                   [vim.diagnostic.severity.INFO] = diagnostic.message,
--                   [vim.diagnostic.severity.HINT] = diagnostic.message,
--                 }
--                 return diagnostic_message[diagnostic.severity]
--               end,
--             },
--           }
--         end,
--       })
--
--       require("mason").setup()
--       require("mason-lspconfig").setup {
--         ensure_installed = {
--           "vtsls",
--           "gopls",
--           "lua_ls",
--         },
--         handlers = {
--           -- function(server_name) -- default handler (optional)
--           --   require("lspconfig")[server_name].setup {}
--           -- end,
--           ["vtsls"] = function()
--             require("lspconfig").vtsls.setup {
--               root_dir = require("lspconfig").util.root_pattern(".git", "pnpm-workspace.yaml", "pnpm-lock.yaml", "yarn.lock", "package-lock.json", "bun.lockb"),
--               typescript = {
--                 tsserver = {
--                   maxTsServerMemory = 12288,
--                 },
--               },
--               experimental = {
--                 completion = {
--                   entriesLimit = 3,
--                 },
--               },
--             }
--           end,
--         },
--       }
--     end,
--   },
-- }
