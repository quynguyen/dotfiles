return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        solargraph = {},
        rust_analyzer = {},
        html = {},
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    dependencies = {
      "nvim-cmp",
    },
  },
  {
    "windwp/nvim-ts-autotag",
    dependencies = {
      "nvim-treesitter",
    },
  },
  {
    "RRethy/nvim-treesitter-endwise",
    dependencies = {
      "nvim-treesitter",
    },
  },
  {
    "RRethy/nvim-treesitter-textsubjects",
    dependencies = {
      "nvim-treesitter",
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "ruby",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "+",
          node_incremental = "+",
          scope_incremental = false,
          node_decremental = "-",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
          goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
          goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
          goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
        },
      },
      autotag = { enable = true },
      endwise = { enable = true },
      textsubjects = {
        enable = true,
        prev_selection = ",", -- (Optional) keymap to select the previous selection
        keymaps = {
          ["."] = "textsubjects-smart",
          [";"] = "textsubjects-container-outer",
          ["i;"] = "textsubjects-container-inner",
        },
      },
    },
  },
}
