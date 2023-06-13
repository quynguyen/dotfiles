return {
  {
    "neovim/nvim-lspconfig",
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        -- pyright will be automatically installed with mason and loaded with lspconfig
        bashls = {},
        ruby_ls = {},
        solargraph = {},
        kotlin_language_server = {},
        rust_analyzer = {},
        html = {},
      },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({
        -- Configuration here, or leave empty to use defaults
      })
    end,
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
      ensure_installed = {
        "lua",
        "vim",
        "bash",
        "regex",
        "awk",
        "diff",
        "html",
        "css",
        "scss",
        "javascript",
        "json",
        "jq",
        "typescript",
        "tsx",
        "graphql",
        "yaml",
        "toml",
        "markdown",
        "markdown_inline",
        "c",
        "cpp",
        "go",
        "rust",
        "ruby",
        "python",
        "kotlin",
        "java",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "+",
          node_incremental = "+",
          scope_incremental = "<c-s>",
          node_decremental = "-",
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
  -- {
  --   "mason-lspconfig",
  --   opts = {
  --     ensure_installed = {
  --       "bashls",
  --       "lua_ls",
  --       "rust_analyzer",
  --       "ruby_ls",
  --       "solargraph",
  --       "sorbet",
  --       "tsserver",
  --       "jsonls",
  --       "cssls",
  --       "cssmodules_ls",
  --       "html",
  --       "kotlin_language_server",
  --     },
  --   },
  -- },
}
