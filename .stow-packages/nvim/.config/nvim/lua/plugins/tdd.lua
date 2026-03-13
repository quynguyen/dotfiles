-- TDD workspace: layout automation, watcher terminal, TCR toggle.
-- State is module-level (shared across all key handlers via closure).
-- vim.g.tdd_tcr_active is set for statusline access without module dependency.

local watcher_terminal = nil  -- Snacks.terminal object (watcher or TCR)
local tcr_active = false

-- ─── Language Root Detection ──────────────────────────────────────────────────
-- Walk up from start_dir to the git root, searching for a language marker file.
-- Returns (lang_root_path, watcher_cmd) or (nil, nil).

local LANG_MARKERS = {
  { file = "mix.exs",          cmd = "mix test.watch" },
  { file = "pyproject.toml",   cmd = "uv run ptw" },
  { file = "package.json",     cmd = "pnpm vitest watch" },
  { file = "Gemfile",          cmd = "bundle exec guard" },
  { file = "build.gradle.kts", cmd = "./gradlew test --continuous" },
  { file = "build.gradle",     cmd = "./gradlew test --continuous" },
}

local function find_language_root(start_dir)
  local git_root = vim.trim(vim.fn.system(
    "git -C " .. vim.fn.shellescape(start_dir) .. " rev-parse --show-toplevel"
  ))
  if vim.v.shell_error ~= 0 or git_root == "" then
    return nil, nil
  end
  local dir = start_dir
  while true do
    for _, marker in ipairs(LANG_MARKERS) do
      if vim.fn.filereadable(dir .. "/" .. marker.file) == 1 then
        return dir, marker.cmd
      end
    end
    if dir == git_root or dir == "/" then
      break
    end
    dir = vim.fn.fnamemodify(dir, ":h")
  end
  return nil, nil
end

-- ─── Alternate File Pairing ───────────────────────────────────────────────────
-- Returns the paired test↔impl absolute path, or nil if no rule matches.

local function get_alternate(path)
  -- Elixir: .../test/foo_test.exs  <->  .../lib/foo.ex
  local ex_base, ex_stem = path:match("^(.*)/test/(.+)_test%.exs$")
  if ex_base then return ex_base .. "/lib/" .. ex_stem .. ".ex" end
  local lib_base, lib_stem = path:match("^(.*)/lib/(.+)%.ex$")
  if lib_base then return lib_base .. "/test/" .. lib_stem .. "_test.exs" end

  local dir  = vim.fn.fnamemodify(path, ":h")
  local name = vim.fn.fnamemodify(path, ":t")

  -- Python: test_foo.py  <->  foo.py
  local py = name:match("^test_(.+%.py)$")
  if py then return dir .. "/" .. py end
  if name:match("%.py$") and not name:match("^test_") then
    return dir .. "/test_" .. name
  end

  -- TypeScript: foo.test.ts  <->  foo.ts
  local ts = name:match("^(.+)%.test%.ts$")
  if ts then return dir .. "/" .. ts .. ".ts" end
  if name:match("%.ts$") and not name:match("%.test%.ts$") and not name:match("%.d%.ts$") then
    return dir .. "/" .. vim.fn.fnamemodify(name, ":r") .. ".test.ts"
  end

  -- TypeScript React: foo.test.tsx  <->  foo.tsx
  local tsx = name:match("^(.+)%.test%.tsx$")
  if tsx then return dir .. "/" .. tsx .. ".tsx" end
  if name:match("%.tsx$") and not name:match("%.test%.tsx$") then
    return dir .. "/" .. vim.fn.fnamemodify(name, ":r") .. ".test.tsx"
  end

  -- JavaScript: foo.test.js  <->  foo.js
  local js = name:match("^(.+)%.test%.js$")
  if js then return dir .. "/" .. js .. ".js" end
  if name:match("%.js$") and not name:match("%.test%.js$") then
    return dir .. "/" .. vim.fn.fnamemodify(name, ":r") .. ".test.js"
  end

  -- Ruby: .../spec/foo_spec.rb  <->  .../lib/foo.rb  (conventional lib/spec layout)
  --       foo_spec.rb  <->  foo.rb  (flat layout fallback)
  local rb_spec_base, rb_spec_stem = path:match("^(.*)/spec/(.+)_spec%.rb$")
  if rb_spec_base then return rb_spec_base .. "/lib/" .. rb_spec_stem .. ".rb" end
  local rb_lib_base, rb_lib_stem = path:match("^(.*)/lib/(.+)%.rb$")
  if rb_lib_base then return rb_lib_base .. "/spec/" .. rb_lib_stem .. "_spec.rb" end
  -- flat layout fallback
  local rb = name:match("^(.+)_spec%.rb$")
  if rb then return dir .. "/" .. rb .. ".rb" end
  if name:match("%.rb$") and not name:match("_spec%.rb$") then
    return dir .. "/" .. vim.fn.fnamemodify(name, ":r") .. "_spec.rb"
  end

  -- Kotlin: FooTest.kt  <->  Foo.kt
  local kt = name:match("^(.+)Test%.kt$")
  if kt then return dir .. "/" .. kt .. ".kt" end
  if name:match("%.kt$") and not name:match("Test%.kt$") then
    return dir .. "/" .. vim.fn.fnamemodify(name, ":r") .. "Test.kt"
  end

  -- Java: FooTest.java  <->  Foo.java
  local jv = name:match("^(.+)Test%.java$")
  if jv then return dir .. "/" .. jv .. ".java" end
  if name:match("%.java$") and not name:match("Test%.java$") then
    return dir .. "/" .. vim.fn.fnamemodify(name, ":r") .. "Test.java"
  end

  return nil
end

local function is_test_file(path)
  local name = vim.fn.fnamemodify(path, ":t")
  return name:match("^test_") ~= nil
    or name:match("_test%.exs?$") ~= nil
    or name:match("%.test%.[jt]sx?$") ~= nil
    or name:match("_spec%.rb$") ~= nil
    or name:match("Test%.kt$") ~= nil
    or name:match("Test%.java$") ~= nil
end

-- ─── Terminal State ───────────────────────────────────────────────────────────

local function terminal_is_open()
  return watcher_terminal ~= nil
    and watcher_terminal.win ~= nil
    and vim.api.nvim_win_is_valid(watcher_terminal.win)
end

-- ─── <leader>tw: TDD Layout ───────────────────────────────────────────────────
-- Idempotent: if the watcher terminal is already open, just focus the left split.
-- Otherwise: close all other windows, open test + impl vsplits, start watcher.

local function setup_tdd_layout()
  if terminal_is_open() then
    vim.cmd("wincmd h")
    vim.cmd("wincmd h")
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("TDD layout: save the file first", vim.log.levels.WARN)
    return
  end

  local alt = get_alternate(path)
  local test_path, impl_path
  if is_test_file(path) then
    test_path = path
    impl_path = alt
  else
    test_path = alt
    impl_path = path
  end

  -- Close all splits and set up test | impl layout
  vim.cmd("only")
  vim.cmd("edit " .. vim.fn.fnameescape(test_path or path))
  if impl_path then
    vim.cmd("vsplit " .. vim.fn.fnameescape(impl_path))
  else
    vim.cmd("vsplit")
  end

  -- Start watcher in bottom split
  local bufdir = vim.fn.fnamemodify(path, ":h")
  local lang_root, watcher_cmd = find_language_root(bufdir)
  if lang_root and watcher_cmd then
    watcher_terminal = require("snacks").terminal.open(watcher_cmd, {
      cwd = lang_root,
      win = { position = "bottom", height = 0.2 },
    })
  else
    vim.notify("TDD layout: could not detect language root from " .. bufdir, vim.log.levels.WARN)
  end

  -- Focus test (left) split
  vim.cmd("wincmd h")
  vim.cmd("wincmd h")
end

-- ─── <leader>ta: Jump to Alternate ───────────────────────────────────────────

local function jump_to_alternate()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then return end
  local alt = get_alternate(path)
  if alt then
    vim.cmd("edit " .. vim.fn.fnameescape(alt))
  else
    vim.notify("No alternate file for: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.WARN)
  end
end

-- ─── <leader>tc: TCR Toggle ───────────────────────────────────────────────────
-- ON:  close watcher terminal, open TCR terminal, add BufWritePost → tcr.sh
-- OFF: clear BufWritePost, close TCR terminal, reopen watcher terminal

local TCR_SCRIPT = vim.fn.expand("~/projects/hacking/scripts/tcr.sh")

local function toggle_tcr()
  local path = vim.api.nvim_buf_get_name(0)
  local bufdir = vim.fn.fnamemodify(path ~= "" and path or vim.fn.getcwd(), ":h")
  local lang_root, watcher_cmd = find_language_root(bufdir)

  if not tcr_active then
    if not lang_root then
      vim.notify("TCR: could not detect language root", vim.log.levels.WARN)
      return
    end
    -- Check TCR script exists
    if vim.fn.filereadable(TCR_SCRIPT) ~= 1 then
      vim.notify("TCR: script not found: " .. TCR_SCRIPT, vim.log.levels.ERROR)
      return
    end
    -- Replace watcher with a display terminal (bash shell, passive)
    if watcher_terminal then
      watcher_terminal:close()
      watcher_terminal = nil
    end
    watcher_terminal = require("snacks").terminal.open("bash", {
      cwd = lang_root,
      win = { position = "bottom", height = 0.2 },
    })
    -- Run tcr.sh on every save via jobstart (non-blocking)
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("tcr_on_save", { clear = true }),
      pattern = "*",
      callback = function()
        local cur = vim.api.nvim_buf_get_name(0)
        local cdir = vim.fn.fnamemodify(cur ~= "" and cur or vim.fn.getcwd(), ":h")
        local root, _ = find_language_root(cdir)
        if root then
          local output = {}
          vim.fn.jobstart({ TCR_SCRIPT }, {
            cwd = root,
            stdout_buffered = true,
            stderr_buffered = true,
            on_stdout = function(_, data)
              for _, line in ipairs(data) do
                if line ~= "" then table.insert(output, line) end
              end
            end,
            on_stderr = function(_, data)
              for _, line in ipairs(data) do
                if line ~= "" then table.insert(output, line) end
              end
            end,
            on_exit = function(_, code)
              local msg = table.concat(output, "\n")
              if msg ~= "" then
                vim.schedule(function()
                  vim.notify(msg, code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
                end)
              end
            end,
          })
        end
      end,
    })
    tcr_active = true
    vim.g.tdd_tcr_active = true
    vim.notify("TCR ON — every save commits (pass) or reverts (fail)", vim.log.levels.INFO)
  else
    -- Clear TCR autocmd, close TCR terminal, restart watcher
    vim.api.nvim_create_augroup("tcr_on_save", { clear = true })
    if watcher_terminal then
      watcher_terminal:close()
      watcher_terminal = nil
    end
    if lang_root and watcher_cmd then
      watcher_terminal = require("snacks").terminal.open(watcher_cmd, {
        cwd = lang_root,
        win = { position = "bottom", height = 0.2 },
      })
    end
    tcr_active = false
    vim.g.tdd_tcr_active = false
    vim.notify("TCR OFF — watcher restarted", vim.log.levels.INFO)
  end
end

-- ─── Plugin Spec ─────────────────────────────────────────────────────────────
return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>tW", setup_tdd_layout, desc = "TDD: Set up workspace layout" },
      { "<leader>tA", jump_to_alternate, desc = "TDD: Jump to alternate file" },
      { "<leader>tc", toggle_tcr,        desc = "TDD: Toggle TCR mode" },
      {
        "<leader>tj",
        function()
          if watcher_terminal and watcher_terminal.win and vim.api.nvim_win_is_valid(watcher_terminal.win) then
            vim.api.nvim_set_current_win(watcher_terminal.win)
          end
        end,
        desc = "TDD: Focus watcher/TCR terminal",
      },
    },
  },
}
