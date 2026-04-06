-- Worktree picker using worktrunk (wt) for listing and creation.
-- On switch: remaps open buffers from old worktree root to new one.
-- Missing files: prompts to close or keep pointing at old path.

-- Tracks the last worktree root we switched to. Initialized lazily from git.
local current_root = nil

local function get_current_root()
  if not current_root then
    local r = vim.trim(vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"))
    if vim.v.shell_error == 0 and r ~= "" then current_root = r end
  end
  return current_root
end

-- Remap all file buffers from old_root → new_root.
-- Returns a list of {buf, rel_path} for files missing in the new worktree.
local function remap_buffers(old_root, new_root)
  local missing = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not (vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted) then goto continue end
    local old_path = vim.api.nvim_buf_get_name(buf)
    if old_path == "" or old_path:match("^term://") then goto continue end
    if old_path:sub(1, #old_root) ~= old_root then goto continue end

    local rel = old_path:sub(#old_root + 1)  -- e.g. "/python/katas/calc.py"
    local new_path = new_root .. rel

    if vim.fn.filereadable(new_path) == 1 then
      local new_buf = vim.fn.bufadd(new_path)
      vim.bo[new_buf].buflisted = true  -- bufadd doesn't list by default
      vim.fn.bufload(new_buf)
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        vim.api.nvim_win_set_buf(win, new_buf)
      end
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    else
      table.insert(missing, { buf = buf, rel = rel })
    end
    ::continue::
  end
  return missing
end

local function handle_missing(missing, new_root)
  if #missing == 0 then return end
  local names = vim.tbl_map(function(m) return "  " .. m.rel end, missing)
  local prompt = #missing .. " file(s) not in new worktree:\n" .. table.concat(names, "\n")
  vim.ui.select(
    { "Close them", "Keep pointing to old paths" },
    { prompt = prompt },
    function(choice)
      if choice == "Close them" then
        for _, m in ipairs(missing) do
          pcall(vim.api.nvim_buf_delete, m.buf, { force = true })
        end
      end
      -- "Keep" = do nothing; buffers stay open pointing at old paths
    end
  )
end

local function switch_to(new_root)
  local old_root = get_current_root()
  local has_old = old_root and old_root ~= new_root

  vim.cmd("cd " .. vim.fn.fnameescape(new_root))
  current_root = new_root
  vim.notify("Switched to: " .. new_root, vim.log.levels.INFO)

  if has_old then
    local missing = remap_buffers(old_root, new_root)
    handle_missing(missing, new_root)
  end
end

local function pick_worktree()
  local raw = vim.fn.system("wt list --format=json 2>/dev/null")
  if vim.v.shell_error ~= 0 or raw == "" then
    vim.notify("Worktree picker: wt list failed", vim.log.levels.WARN)
    return
  end
  local ok, list = pcall(vim.json.decode, raw)
  if not ok or type(list) ~= "table" then
    vim.notify("Worktree picker: could not parse wt list JSON", vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, wt in ipairs(list) do
    if wt.path and wt.kind == "worktree" then
      local wt_info = wt.working_tree
      local dirty = (wt_info and (wt_info.modified or wt_info.staged or wt_info.untracked)) and " *" or ""
      local label = (wt.branch or "detached") .. dirty
      table.insert(items, {
        text  = label .. "  " .. wt.path,
        path  = wt.path,
        file  = wt.path,
        label = label,
      })
    end
  end

  if #items == 0 then
    vim.notify("No worktrees found", vim.log.levels.WARN)
    return
  end

  require("snacks").picker.pick("worktrees", {
    title = "Git Worktrees",
    finder = function() return items end,
    format = function(item) return { { item.text } } end,
    confirm = function(picker, item)
      picker:close()
      switch_to(item.path)
    end,
  })
end

local function create_worktree()
  vim.ui.input({ prompt = "New branch name: " }, function(branch)
    if not branch or branch == "" then return end
    local result = vim.fn.system("wt switch --create " .. vim.fn.shellescape(branch))
    if vim.v.shell_error == 0 then
      vim.notify("Created worktree: " .. branch, vim.log.levels.INFO)
    else
      vim.notify("wt switch --create failed:\n" .. result, vim.log.levels.ERROR)
    end
  end)
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gw", pick_worktree,   desc = "Worktree: switch" },
      { "<leader>gW", create_worktree, desc = "Worktree: create new" },
    },
  },
}
