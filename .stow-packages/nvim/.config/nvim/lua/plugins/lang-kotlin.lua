-- Kotlin: kotlin-language-server (via Mason) + ktlint formatter/linter.
-- LazyVim v15 has no lang.kotlin extra; this spec provides full coverage.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        kotlin = { "ktlint" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        kotlin = {},
      },
    },
  },
}
