-- ~/.config/nvim/lua/plugins.lua
return {
  -- Other plugins

  -- CamelCaseMotion plugin
  {
    "bkad/CamelCaseMotion",
    config = function()
      -- Optional: Set custom key mappings for CamelCaseMotion
      vim.api.nvim_set_keymap("n", "w", "<Plug>CamelCaseMotion_w", {})
      vim.api.nvim_set_keymap("n", "b", "<Plug>CamelCaseMotion_b", {})
      vim.api.nvim_set_keymap("n", "e", "<Plug>CamelCaseMotion_e", {})
      vim.api.nvim_set_keymap("n", "ge", "<Plug>CamelCaseMotion_ge", {})
      vim.api.nvim_set_keymap("x", "w", "<Plug>CamelCaseMotion_w", {})
      vim.api.nvim_set_keymap("x", "b", "<Plug>CamelCaseMotion_b", {})
      vim.api.nvim_set_keymap("x", "e", "<Plug>CamelCaseMotion_e", {})
      vim.api.nvim_set_keymap("x", "ge", "<Plug>CamelCaseMotion_ge", {})
    end,
  },

  -- Optionally, add vim-sneak as well
  {
    "justinmk/vim-sneak",
    config = function()
      -- Enable sneak label highlighting
      vim.g["sneak#label"] = 1
    end,
  },
}
