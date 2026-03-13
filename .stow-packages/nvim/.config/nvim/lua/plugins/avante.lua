-- Configure avante.nvim to use Claude (Anthropic) as the AI provider.
-- The ai.avante LazyVim extra installs avante but defaults to Copilot.
-- Requires ANTHROPIC_API_KEY env var to be set.
return {
  {
    "yetone/avante.nvim",
    opts = {
      provider = "claude",
      claude = {
        endpoint = "https://api.anthropic.com",
        model = "claude-sonnet-4-5",
        timeout = 30000,
        temperature = 0,
        max_tokens = 8096,
      },
    },
  },
}
