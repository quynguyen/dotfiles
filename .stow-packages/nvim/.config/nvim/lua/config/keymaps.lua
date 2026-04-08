-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Treesitter incremental selection: + to expand, - to shrink
vim.keymap.set("n", "+", function()
  require("nvim-treesitter.incremental_selection").init_selection()
end, { desc = "Expand selection" })
vim.keymap.set("v", "+", function()
  require("nvim-treesitter.incremental_selection").node_incremental()
end, { desc = "Expand selection" })
vim.keymap.set("v", "-", function()
  require("nvim-treesitter.incremental_selection").node_decremental()
end, { desc = "Shrink selection" })
