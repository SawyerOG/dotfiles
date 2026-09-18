return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && npm install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" }, -- Added missing comma here
  config = function()
    -- Force the preview server to listen on all interfaces
    vim.g.mkdp_open_to_the_world = 1 

    -- Bind explicitly to localhost loopback so Windows can reach it
    vim.g.mkdp_open_ip = "127.0.0.1" 

    -- Explicitly specify a static port so your URL never changes 
    vim.g.mkdp_port = "1337" 

    -- Echo the exact URL link directly to the command bar when you run it
    vim.g.mkdp_echo_preview_url = 1 

    vim.cmd([[
      function! SilentNoOpBrowser(url)
        " Do absolutely nothing here
      endfunction
    ]])

    vim.g.mkdp_browserfunc = "SilentNoOpBrowser"
  end,
}
