-- Patches for snacks.nvim bugs that survive :Lazy update.
return {
  {
    "folke/snacks.nvim",
    config = function(_, opts)
      require("snacks").setup(opts)
      -- Patch: dashboard augroup deleted twice (BufWipeout + BufDelete both fire),
      -- causing "invalid augroup id" error on buffer close. Use pcall to swallow the
      -- second deletion. Re-applies on every Neovim start; survives :Lazy update.
      local dashboard_ok, dashboard = pcall(require, "snacks.dashboard")
      if dashboard_ok and dashboard.Dashboard then
        local orig_close = dashboard.Dashboard.close
        if orig_close then
          dashboard.Dashboard.close = function(self, ...)
            pcall(orig_close, self, ...)
          end
        end
      end
    end,
  },
}
