-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Treesitter incremental selection: + to expand, - to shrink
vim.keymap.set({ "n", "x" }, "+", function()
  require("flash").treesitter({
    actions = { ["+"] = "next", ["-"] = "prev" },
  })
end, { desc = "Expand selection" })

-- Spell check toggles (leader + bracket style)
vim.keymap.set("n", "<leader>us", function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  local status = vim.opt_local.spell:get() and "on" or "off"
  vim.notify("Spell check " .. status, vim.log.levels.INFO)
end, { desc = "Toggle spell check" })

-- Tim Pope style bracket toggles for spell
vim.keymap.set("n", "[os", function()
  vim.opt_local.spell = true
  vim.notify("Spell check on", vim.log.levels.INFO)
end, { desc = "Enable spell check" })

vim.keymap.set("n", "]os", function()
  vim.opt_local.spell = false
  vim.notify("Spell check off", vim.log.levels.INFO)
end, { desc = "Disable spell check" })
