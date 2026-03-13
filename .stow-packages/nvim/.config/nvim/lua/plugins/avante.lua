-- Configure avante.nvim to use Gemini as the AI provider.
-- Requires GEMINI_API_KEY env var — get a free key at https://aistudio.google.com/apikey
-- Uses the new `providers` config format (avante v0.x deprecated top-level provider tables).
return {
  {
    "yetone/avante.nvim",
    opts = {
      provider = "gemini",
      providers = {
        gemini = {
          model = "gemini-2.5-pro-exp-03-25",
        },
      },
    },
  },
}
