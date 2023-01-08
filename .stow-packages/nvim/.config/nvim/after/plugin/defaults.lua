require('lualine').setup {
  options = {
    theme = 'dracula',
  },
}

require('nvim-treesitter.configs').setup {
  -- ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'typescript', 'help', 'html', 'javascript', 'java', 'ruby', 'graphql', 'markdown'  },
  ensure_installed = 'all',
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '+',
      node_incremental = '+',
      scope_incremental = '<c-s>',
      node_decremental = '-',
    },
  },
  autotag = { enable = true },
  endwise = { enable = true },
  textsubjects = {
    enable = true,
    prev_selection = ',', -- (Optional) keymap to select the previous selection
    keymaps = {
      ['.'] = 'textsubjects-smart',
      [';'] = 'textsubjects-container-outer',
      ['i;'] = 'textsubjects-container-inner',
    },
  },
}

local luasnip = require('luasnip')
local cmp = require('cmp')
cmp.setup {
  mapping = cmp.mapping.preset.insert {
    ['<C-Space>'] = cmp.mapping.complete({}),
    ['<C-]>'] = cmp.mapping.close(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<C-J>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-K>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
}

local opts = { prefix = "<leader>" }
local mappings = {
  s = {
    name = "[S]earch"
  },
  c = {
    name = "[C]ode"
  },
  w = {
    name = "[W]orkspace"
  },
  e = { ":!ruby %<CR>", "Execute Ruby" },
  b = { ":!bundle exec rspec %<CR>", "Bundle exec" },
  r = { ":!rspec . --color --format doc<CR>", "Rspec" },
  f = { ":Format<CR>", "Format" },
  i = { "m'gg=G''", "Indent" },
}

require('which-key').register(mappings, opts)

require('nvim-autopairs').setup({})


vim.o.clipboard = "unnamedplus"
vim.o.timeoutlen = 50
vim.cmd [[colorscheme dracula]]
