-- neotest adapters for Python, TypeScript/JS, Elixir, Ruby, Java.
-- BufWritePost autocmd runs nearest test on save (allowlisted filetypes only).
-- Java: manual only (Gradle cold-start too slow; requires jdtls attached — check :LspInfo).
-- Kotlin: no adapter available — watcher only.
return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
      "jfpedroza/neotest-elixir",
      "olimorris/neotest-rspec",
      "rcasia/neotest-java",
    },
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      vim.list_extend(opts.adapters, {
        require("neotest-python"),
        require("neotest-vitest"),
        require("neotest-elixir"),
        require("neotest-rspec"),
        require("neotest-java"),
      })
    end,
    keys = {
      {
        "<leader>tE",
        function()
          require("neotest").jump.next({ status = "failed" })
        end,
        desc = "Jump to next failing test",
      },
    },
    init = function()
      -- Allowlist: only filetypes with a confirmed neotest adapter.
      -- Run neotest.run.run() with no args = nearest test at cursor.
      -- neotest handles "is this a test file?" internally; non-test files silently no-op.
      local ALLOWED_FT = {
        python = true,
        elixir = true,
        typescript = true,
        typescriptreact = true,
        javascript = true,
        javascriptreact = true,
        ruby = true,
      }
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("neotest_run_on_save", { clear = true }),
        pattern = "*",
        callback = function(event)
          if ALLOWED_FT[vim.bo[event.buf].filetype] then
            require("neotest").run.run()
          end
        end,
      })
    end,
  },
}
