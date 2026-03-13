-- Custom Snacks.picker worktree switcher + creator.
-- No telescope dependency. Worktrees created at ~/projects/hacking-wt/<branch>/.
-- Branch names with slashes (feature/foo) are sanitized to feature-foo for directory names.

local function list_worktrees()
  local lines = vim.fn.systemlist("git worktree list")
  local items = {}
  for _, line in ipairs(lines) do
    local path, rest = line:match("^(%S+)%s+(.+)$")
    if path then
      table.insert(items, { text = line, path = path, label = rest })
    end
  end
  return items
end

local function pick_worktree()
  local items = list_worktrees()
  if #items == 0 then
    vim.notify("No git worktrees found (not in a git repo?)", vim.log.levels.WARN)
    return
  end
  require("snacks").picker.pick("worktrees", {
    title = "Git Worktrees",
    finder = function()
      return items
    end,
    format = function(item)
      return { { item.text } }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.cmd("cd " .. vim.fn.fnameescape(item.path))
      vim.notify("Switched to: " .. item.path, vim.log.levels.INFO)
    end,
  })
end

local function create_worktree()
  vim.ui.input({ prompt = "New branch name: " }, function(branch)
    if not branch or branch == "" then return end
    -- Sanitize: slashes → dashes (for directory name only; git branch keeps slashes)
    local safe_name = branch:gsub("/", "-")
    local wt_path = vim.fn.expand("~/projects/hacking-wt/") .. safe_name
    local result = vim.fn.system(
      "git worktree add " .. vim.fn.shellescape(wt_path) .. " -b " .. vim.fn.shellescape(branch)
    )
    if vim.v.shell_error == 0 then
      vim.notify("Created worktree at: " .. wt_path, vim.log.levels.INFO)
    else
      vim.notify("git worktree add failed:\n" .. result, vim.log.levels.ERROR)
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
