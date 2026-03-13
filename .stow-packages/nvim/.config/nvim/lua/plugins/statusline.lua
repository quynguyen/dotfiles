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

      -- Prepend so they appear before filetype/encoding indicators
      table.insert(opts.sections.lualine_x, 1, sm_component)
      table.insert(opts.sections.lualine_x, 1, tcr_component)
    end,
  },
}
