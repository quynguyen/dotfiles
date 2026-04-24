-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Prepend Homebrew Ruby to PATH so Mason uses Ruby 4.x instead of system Ruby 2.6.
-- Required for ruby-lsp (needs Ruby >= 3.1).
if vim.fn.isdirectory("/opt/homebrew/opt/ruby/bin") == 1 then
  vim.env.PATH = "/opt/homebrew/opt/ruby/bin:" .. vim.env.PATH
end

-- Use custom SCOWL spell file for better technical term coverage
vim.opt.spellfile = vim.fn.expand("~/.config/nvim/spell/en.utf-8.add")
