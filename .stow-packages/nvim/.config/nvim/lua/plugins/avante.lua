-- Configure avante.nvim to use Gemini as the AI provider.
-- Requires GEMINI_API_KEY env var — get a free key at https://aistudio.google.com/apikey
-- Uses the new `providers` config format (avante v0.x deprecated top-level provider tables).
return {
  {
    "yetone/avante.nvim",
    opts = {
      mode = "legacy",
      provider = "gemini",
      providers = {
        gemini = {
          model = "gemini-2.5-pro",
          -- Read key from macOS Keychain instead of env var.
          -- Store once with: security add-generic-password -a "$USER" -s GEMINI_API_KEY -w "your-key"
          api_key_name = "cmd:security find-generic-password -a " .. vim.fn.expand("$USER") .. " -s GEMINI_API_KEY -w",
        },
      },
    },
    config = function(_, opts)
      require("avante").setup(opts)
      -- Patch: auto-scroll triggers when within 5 lines of bottom (upstream uses 1).
      -- Survives :Lazy update; re-applies on every Neovim start.
      local Sidebar = require("avante.sidebar")
      local api = vim.api
      Sidebar.should_auto_scroll = function(self)
        if not self.containers.result or not self.containers.result.winid then return false end
        if not api.nvim_win_is_valid(self.containers.result.winid) then return false end
        local win_height = api.nvim_win_get_height(self.containers.result.winid)
        local total_lines = api.nvim_buf_line_count(self.containers.result.bufnr)
        local topline = vim.fn.line("w0", self.containers.result.winid)
        local last_visible_line = topline + win_height - 1
        return last_visible_line >= total_lines - 5
      end
    end,
  },
  {
    "saghen/blink.cmp",
    opts = {
      enabled = function()
        return not vim.tbl_contains({ "AvanteInput", "AvantePromptInput" }, vim.bo.filetype)
      end,
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
  },
}
