-- Elixir: Expert LSP (official, built on Lexical) + credo linting via nvim-lint.
-- DO NOT enable lazyvim.plugins.extras.lang.elixir — it installs elixir-ls,
-- which would double-attach alongside Expert on .ex/.exs files.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "elixir", "heex", "eex" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        expert = {},
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        elixir = { "credo" },
      },
    },
  },
}
