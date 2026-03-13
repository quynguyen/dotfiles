-- Supermaven AI ghost-text autocomplete.
-- Loaded normally but stopped immediately in config — off by default.
-- Toggle with <leader>ac. blink.cmp LSP completions are always active regardless.
-- Tab conflict note: if <Tab> conflicts with blink.cmp, change accept_suggestion to <C-f>.
-- accept_word uses <C-k> — <C-j> is reserved for TDD terminal focus (tdd.lua).
return {
  {
    "supermaven-inc/supermaven-nvim",
    event = "InsertEnter",
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion = "<C-]>",
        accept_word = "<C-k>",
      },
      ignore_filetypes = {},
      log_level = "off",
      disable_inline_completion = false,
      disable_keymaps = false,
    },
    config = function(_, opts)
      require("supermaven-nvim").setup(opts)
      -- Stop immediately: ghost-text off by default
      require("supermaven-nvim.api").stop()
      vim.g.supermaven_active = false
    end,
    keys = {
      {
        "<leader>ac",
        function()
          require("supermaven-nvim.api").toggle()
          vim.g.supermaven_active = not (vim.g.supermaven_active == true)
          local state = vim.g.supermaven_active and "ON" or "OFF"
          vim.notify("Supermaven ghost-text " .. state, vim.log.levels.INFO)
        end,
        desc = "Toggle Supermaven ghost-text",
      },
    },
  },
}
