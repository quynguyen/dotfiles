-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set(
  "n",
  "<leader>sx",
  require("telescope.builtin").resume,
  { noremap = true, silent = true, desc = "Resume" }
)

vim.cmd([[
" Top 5 vimrc remaps from this crazy mofo
" https://www.youtube.coim/watch?v=hSHATqh8svM
"================================================================================================ 
" Capital "D", and Capital "C" effects from the cursor to the end of the line.
" Yet, Capital "Y" yanks the entire line.  Why?  Make "Y" yank from the cursor
" until the end of the line
nnoremap Y y$

" When the cursor jumps during finds or joins, have the screen/camera track
" the cursor, keeping the cursor in the middle.  This is a like the David
" Fincher camera think, or keeping the subject centered in frame, even if the
" subject is moving ever so slightly
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z

" This is a helpful ditty to undo just a phrase, or sentence, rather than a whole line.
" Create undo-breakss for a comma, period, exclamation, or question mark; whatever really.
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u

noremap <expr> k (v:count > 5 ? "m'" . v:count : "") . 'k'
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . 'j'
]])
