-- Custom lualine components: [TCR] and [SM].
-- Both read vim.g flags set by tdd.lua and supermaven.lua respectively.
-- Return "" when inactive so they take no space in the statusline.
return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}

      local tcr_component = {
        function()
          return vim.g.tdd_tcr_active == true and "[TCR]" or ""
        end,
        color = { fg = "#ff6b6b", gui = "bold" },
        padding = { left = 1, right = 0 },
      }

      local sm_component = {
        function()
          return vim.g.supermaven_active == true and "[SM]" or ""
        end,
        color = { fg = "#51cf66", gui = "bold" },
        padding = { left = 1, right = 0 },
      }

      -- Shows [WT: branch] when in a non-main worktree.
      -- In a bare repo all worktrees are linked, so we suppress for "main" branch.
      local wt_component = {
        function()
          local branch = vim.trim(vim.fn.system("git branch --show-current 2>/dev/null"))
          if vim.v.shell_error ~= 0 or branch == "" or branch == "main" then return "" end
          local git_dir = vim.trim(vim.fn.system("git rev-parse --git-dir 2>/dev/null"))
          -- Only show in a linked worktree (git-dir contains /worktrees/)
          if not git_dir:find("/worktrees/", 1, true) then return "" end
          return "[WT: " .. branch .. "]"
        end,
        color = { fg = "#ffd43b", gui = "bold" },
        padding = { left = 1, right = 0 },
      }

      -- Prepend so they appear before filetype/encoding indicators
      table.insert(opts.sections.lualine_x, 1, sm_component)
      table.insert(opts.sections.lualine_x, 1, tcr_component)
      table.insert(opts.sections.lualine_x, 1, wt_component)
    end,
  },
}
