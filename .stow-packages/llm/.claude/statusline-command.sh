#!/usr/bin/env bash
# Claude Code statusLine — dir, git, model (tier color), context (usage color)

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model_id=$(echo "$input" | jq -r '.model.id // ""')
model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
used_pct=$(echo "$input"  | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input"     | jq -r '.context_window.context_window_size // empty')

# Shorten home to ~
short_cwd=$(echo "$cwd" | sed "s|^${HOME}/|~/|")

# ANSI helpers — Dracula palette
reset=$'\e[0m'
dark_fg=$'\e[38;2;40;42;54m'        # #282a36 dark text on colored backgrounds
light_fg=$'\e[38;2;248;248;242m'    # #f8f8f2 light text on dark backgrounds

# --- Line 1: Starship-style powerline path + git ---

# Starship palette
fg_gray=$'\e[38;2;188;188;188m'
bg_gray=$'\e[48;2;188;188;188m'
fg_path=$'\e[38;2;74;163;232m'     # #4AA3E8 sky blue
bg_path=$'\e[48;2;74;163;232m'
fg_white=$'\e[38;2;255;255;255m'
fg_yellow=$'\e[38;2;252;233;79m'
bg_yellow=$'\e[48;2;252;233;79m'

# Git branch + dirty indicator
git_label=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
        || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  dirty=$(git -C "$cwd" status --porcelain 2>/dev/null | head -1)
  [ -n "$dirty" ] && git_label=" ${branch} *" || git_label=" ${branch}"
fi

line1=""

# Adjacent colored pills — Starship style without powerline glyphs
line1+="${bg_path}${fg_white} 󰉋 ${short_cwd} ${reset}"

if [ -n "$git_label" ]; then
  line1+="${bg_yellow}${dark_fg}${git_label} ${reset}"
fi

# --- Line 2: Original model + context pills ---

# Model tier — detect from ID, color accordingly
model_lower=$(echo "$model_id" | tr '[:upper:]' '[:lower:]')
if echo "$model_lower" | grep -q "opus"; then
  tier="opus"
  tier_label="Best"
  model_bg=$'\e[48;2;189;147;249m'  # Dracula purple  #bd93f9  [Best]
elif echo "$model_lower" | grep -q "haiku"; then
  tier="haiku"
  tier_label="Good"
  model_bg=$'\e[48;2;241;250;140m'  # Dracula yellow  #f1fa8c  [Good]
else
  tier="sonnet"
  tier_label="Better"
  model_bg=$'\e[48;2;139;233;253m'  # Dracula cyan    #8be9fd  [Better]
fi

model_part="${model_bg}${dark_fg} Model: ${tier_label} (${model_name}) ${reset}"

# Context — color by % remaining vs model-specific thresholds, with progress bar
ctx_part=""
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  remaining=$((100 - used_int))

  # Thresholds: % remaining needed for green / yellow
  if [ "$tier" = "sonnet" ]; then
    green_min=60; yellow_min=30
  else
    green_min=70; yellow_min=40   # opus and haiku share same bands
  fi

  if [ "$remaining" -ge "$green_min" ]; then
    ctx_bg=$'\e[48;2;80;250;123m'   # Dracula green  #50fa7b
  elif [ "$remaining" -ge "$yellow_min" ]; then
    ctx_bg=$'\e[48;2;241;250;140m'  # Dracula yellow #f1fa8c
  else
    ctx_bg=$'\e[48;2;255;85;85m'    # Dracula red    #ff5555
  fi

  # Human-readable token counts (k suffix) — derive from percentage × window size
  token_label=""
  if [ -n "$ctx_size" ] && [ "$ctx_size" -gt 0 ] 2>/dev/null; then
    used_tokens=$(printf '%.0f' "$(echo "$used_pct * $ctx_size / 100" | bc -l)")
    used_k=$(( used_tokens / 1000 ))
    max_k=$(( ctx_size / 1000 ))
    token_label="${used_k}k/${max_k}k "
  fi

  ctx_part="${ctx_bg}${dark_fg} ${token_label}(${used_int}%) ${reset}"
fi

printf "%s\n%s%s" "$line1" "$model_part" "$ctx_part"
