return {
  -- {
  --   "pmizio/typescript-tools.nvim", dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   opts = function()
  --     local api = require("typescript-tools.api")
  --
  --     return {
  --       handlers = {
  --         ["textDocument/publishDiagnostics"] = api.filter_diagnostics({
  --           -- var is assigned but never used
  --           6133,
  --         }),
  --       },
  --     }
  --   end,
  -- },
  -- {
  -- 	"folke/lazydev.nvim",
  -- 	ft = "lua",
  -- 	lazy = true,
  -- 	event = "VeryLazy",
  -- 	opts = {
  -- 		library = {
  -- 			-- Load  uvit types when the `vim.uv` word is found
  -- 			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
  -- 		},
  -- 	},
  -- },
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    event = "BufReadPre",
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      -- {
      --   "mason-org/mason-lspconfig.nvim",
      --   opts = {
      --     ensure_installed = { "gopls", "lua_ls", "ts_ls", "pylsp" },
      --     automatic_installation = false,
      --   },
      -- },
      "saghen/blink.cmp",
      {
        "j-hui/fidget.nvim",
        opts = {
          -- options
        },
      },
    },
    -- opts = {
    --   servers = {
    --     pylsp = {
    --       pylsp = {
    --         plugins = {
    --           pyflakes = { enabled = false },
    --           pycodestyle = { enabled = false },
    --           autopep8 = { enabled = false },
    --           yapf = { enabled = false },
    --           mccabe = { enabled = false },
    --           Pylsp_mypy = { enabled = false },
    --           pylsp_black = { enabled = false },
    --           pylsp_isort = { enabled = false },
    --           -- ruff = {
    --           --   enabled = true,
    --           --   formatEnabled = true,
    --           --   lineLength = 88,
    --           --   -- select = { "E", "F", "I" },
    --           --   -- ignore = { "E501" },
    --           -- },
    --         },
    --       },
    --     },
    --   },
    -- },
    config = function()
      -- Defer blink.cmp setup until first insert mode
      vim.api.nvim_create_autocmd("InsertEnter", {
        once = true,
        callback = function()
          require("blink.cmp").setup()
        end,
      })

      local pylsp_config = {
        settings = {
          pylsp = {
            plugins = {
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false },
              ruff = {
                enabled = true,
                formatEnabled = true,
                lineLength = 88,
                select = { "E", "F", "I" },
                -- ignore = { "E501" },
              },
            },
          },
        },
      }

      local lsp_setup_done = {}

      local function setup_lsp(server, ft_pattern, config)
        vim.api.nvim_create_autocmd("BufEnter", {
          pattern = ft_pattern,
          callback = function()
            if lsp_setup_done[server] then
              return
            end
            lsp_setup_done[server] = true
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

            -- require("lspconfig")[server].setup { capabilities = capabilities }
            local lsp_config = vim.tbl_deep_extend("force", { capabilities = capabilities }, config or {})
            require("lspconfig")[server].setup(lsp_config)
          end,
        })
      end

      setup_lsp("gopls", "go")
      setup_lsp("lua_ls", "lua")
      setup_lsp("ts_ls", { "typescript", "javascript", "typescriptreact", "javascriptreact" })
      setup_lsp("pylsp", "python", pylsp_config)
      --
      -- -- Example LspAttach autocommand (customize as needed)
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
    end,
  },

  -- {
  -- 	"neovim/nvim-lspconfig",
  -- 	dependencies = {
  -- 		{
  -- 			"mason-org/mason.nvim",
  -- 			opts = {},
  -- 		},
  -- 		{
  -- 			"mason-org/mason-lspconfig.nvim",
  -- 			opts = {},
  -- 		},
  -- 		"saghen/blink.cmp"
  -- 	},
  -- 	config = function()
  -- 		local capabilities = vim.lsp.protocol.make_client_capabilities()
  -- 		capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
  --
  -- 		vim.lsp.config("*", {
  -- 			capabilities = capabilities
  --
  -- 		})
  --
  -- 		vim.api.nvim_create_autocmd("LspAttach", {
  -- 			group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
  -- 			callback = function(event)
  -- 				local map = function(keys, func, desc, mode)
  -- 					mode = mode or "n"
  -- 					vim.keymap.set(mode, keys, func,
  -- 						{ buffer = event.buf, desc = "LSP: " .. desc })
  -- 				end
  --
  -- 				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
  -- 				-- Execute a code action, usually your cursor needs to be on top of an error
  -- 				-- or a suggestion from your LSP for this to activate.
  -- 				map("<leader>a", vim.lsp.buf.code_action, "[C]ode [A]ction", { "n", "x" })
  --
  -- 				-- WARN: This is not Goto Definition, this is Goto Declaration.
  -- 				--  For example, in C this would take you to the header.
  -- 				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
  --
  -- 				-- This function resolves a difference between neovim nightly (version 0.11) and stable (version 0.10)
  -- 				---@param client vim.lsp.Client
  -- 				---@param method vim.lsp.protocol.Method
  -- 				---@param bufnr? integer some lsp support methods only in specific files
  -- 				---@return boolean
  -- 				local function client_supports_method(client, method, bufnr)
  -- 					-- if vim.fn.has "nvim-0.11" == 1 then
  -- 					return client:supports_method(method, bufnr)
  -- 					-- else
  -- 					--   return client.supports_method(method, { bufnr = bufnr })
  -- 					-- end
  -- 				end
  --
  -- 				-- The following two autocommands are used to highlight references of the
  -- 				-- word under your cursor when your cursor rests there for a little while.
  -- 				--    See `:help CursorHold` for information about when this is executed
  -- 				--
  -- 				-- When you move your cursor, the highlights will be cleared (the second autocommand).
  -- 				local client = vim.lsp.get_client_by_id(event.data.client_id)
  -- 				if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
  -- 					local highlight_augroup = vim.api.nvim_create_augroup(
  -- 						"kickstart-lsp-highlight", { clear = false })
  -- 					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  -- 						buffer = event.buf,
  -- 						group = highlight_augroup,
  -- 						callback = vim.lsp.buf.document_highlight,
  -- 					})
  --
  -- 					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  -- 						buffer = event.buf,
  -- 						group = highlight_augroup,
  -- 						callback = vim.lsp.buf.clear_references,
  -- 					})
  --
  -- 					vim.api.nvim_create_autocmd("LspDetach", {
  -- 						group = vim.api.nvim_create_augroup("kickstart-lsp-detach",
  -- 							{ clear = true }),
  -- 						callback = function(event2)
  -- 							vim.lsp.buf.clear_references()
  -- 							vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
  -- 						end,
  -- 					})
  -- 				end
  --
  -- 				-- The following code creates a keymap to toggle inlay hints in your
  -- 				-- code, if the language server you are using supports them
  -- 				--
  -- 				-- This may be unwanted, since they displace some of your code
  -- 				if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
  -- 					map("<leader>th", function()
  -- 						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
  -- 					end, "[T]oggle Inlay [H]ints")
  -- 				end
  -- 			end,
  -- 		})
  --
  -- 		-- Diagnostic Config
  -- 		-- See :help vim.diagnostic.Opts
  -- 		vim.diagnostic.config {
  -- 			severity_sort = true,
  -- 			float = { border = "rounded", source = "if_many" },
  -- 			underline = { severity = vim.diagnostic.severity.ERROR },
  -- 			signs = vim.g.have_nerd_font and {
  -- 				text = {
  -- 					[vim.diagnostic.severity.ERROR] = "󰅚 ",
  -- 					[vim.diagnostic.severity.WARN] = "󰀪 ",
  -- 					[vim.diagnostic.severity.INFO] = "󰋽 ",
  -- 					[vim.diagnostic.severity.HINT] = "󰌶 ",
  -- 				},
  -- 			} or {},
  -- 			virtual_text = {
  -- 				source = "if_many",
  -- 				spacing = 2,
  -- 				format = function(diagnostic)
  -- 					local diagnostic_message = {
  -- 						[vim.diagnostic.severity.ERROR] = diagnostic.message,
  -- 						[vim.diagnostic.severity.WARN] = diagnostic.message,
  -- 						[vim.diagnostic.severity.INFO] = diagnostic.message,
  -- 						[vim.diagnostic.severity.HINT] = diagnostic.message,
  -- 					}
  -- 					return diagnostic_message[diagnostic.severity]
  -- 				end,
  -- 			},
  -- 		}
  -- 	end,
  -- },
}
