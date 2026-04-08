-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Treesitter incremental selection: + to expand, - to shrink
vim.keymap.set({ "n", "x" }, "+", function()
  require("flash").treesitter({
    actions = { ["+"] = "next", ["-"] = "prev" },
  })
end, { desc = "Expand selection" })
