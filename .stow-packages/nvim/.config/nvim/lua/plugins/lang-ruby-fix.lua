-- Disable nvim-lint's standalone rubocop for Ruby.
-- ruby-lsp handles rubocop internally; running both causes duplicate diagnostics.
-- The `dependencies` declaration ensures this opts function merges after lang.ruby.
return {
  {
    "mfussenegger/nvim-lint",
    dependencies = { "mfussenegger/nvim-lint" },
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.ruby = {}
    end,
  },
}
