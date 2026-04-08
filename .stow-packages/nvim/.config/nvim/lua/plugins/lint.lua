return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {}, -- disable markdownlint-cli2 for markdown
      },
    },
  },
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        treesitter = {
          label = { before = false, after = false },
        },
      },
    },
  },
}
