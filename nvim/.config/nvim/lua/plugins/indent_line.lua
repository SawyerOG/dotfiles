return {
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',

    event = "InsertEnter",
    lazy = true,
    opts = {
      indent = {
        char = '│', -- Vertical line for all indent guides
      },
      scope = {
        enabled = true, -- Keep scope highlighting on
        char = '│', -- Match scope to indent char
      },
      exclude = {
        filetypes = {}, -- No exclusions unless needed
      },
    },
  },
}
