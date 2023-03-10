
return function(use)
  use 'kyazdani42/nvim-tree.lua'
  use {
    "folke/which-key.nvim",
      config = function()
        require("which-key").setup({})
      end
  }
  use {
    'windwp/nvim-autopairs',
    after = 'nvim-cmp',
  }
  use {
    'windwp/nvim-ts-autotag',
    after = 'nvim-treesitter',
  }
  use {
    'RRethy/nvim-treesitter-endwise',
    after = 'nvim-treesitter',
  }
  use {
    'RRethy/nvim-treesitter-textsubjects',
    after = 'nvim-treesitter',
  }
  use 'akinsho/toggleterm.nvim'
  use 'tpope/vim-surround'
  use 'Mofiqul/dracula.nvim'
  use 'tpope/vim-unimpaired'
end
