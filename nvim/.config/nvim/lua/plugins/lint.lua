return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    vim.env.ESLINT_D_PPID = vim.fn.getpid()
    local lint = require "lint"

    -- Function to check if the current project is a Deno project
    local function is_deno_project()
      local util = require "lspconfig.util"
      local root = util.root_pattern("deno.json", "deno.jsonc")(vim.fn.expand "%:p")
      return root and (vim.fn.filereadable(root .. "/deno.json") > 0 or vim.fn.filereadable(root .. "/deno.jsonc") > 0)
    end

    -- Original linters_by_ft configuration
    local linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
    }

    -- Dynamically set linters_by_ft to empty for Deno projects
    lint.linters_by_ft = vim.tbl_map(function(linters)
      return is_deno_project() and {} or linters
    end, linters_by_ft)

    -- Create autocommand for linting
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        if vim.opt_local.modifiable:get() then
          lint.try_lint()
        end
      end,
    })
  end,
}
