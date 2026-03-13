-- Elixir: Lexical LSP (via Mason) + credo linting via nvim-lint.
-- DO NOT enable lazyvim.plugins.extras.lang.elixir — it installs elixir-ls,
-- which would double-attach alongside Lexical on .ex/.exs files.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lexical = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("mix.exs", ".git")(fname)
          end,
        },
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
