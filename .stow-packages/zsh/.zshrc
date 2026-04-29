# vim: ft=zsh

export DOTFILES_PATH="$HOME/dotfiles"
export PATH="$HOME/.local/bin:$HOME/.bin:$HOME/.claude/bin:$HOME/.bun/bin:$PATH"

# Load shell configuration to determine prompt type
if [[ -f ~/.shell_config ]]; then
  source ~/.shell_config
fi

# Set default if not configured
DOTFILES_SHELL_MODE="${DOTFILES_SHELL_MODE:-zsh-p10k}"

# Configure prompt based on shell mode
if [[ "$DOTFILES_SHELL_MODE" == "zsh-p10k" ]]; then
  # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
  # Initialization code that may require console input (password prompts, [y/n]
  # confirmations, etc.) must go above this block; everything else may go below.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi
fi

# `yazi` -- Terminal file browser with cd on exit
[[ -f ~/.config/yazi/yazicd.sh ]] && source ~/.config/yazi/yazicd.sh

# Bind Ctrl+O to yazi for quick file navigation
bindkey -s '^o' 'yazicd\n'

# Load includes
for file in ~/.zsh/*; do
  source $file
done

# Load plugins
source ~/.zsh_plugins.sh

# Load Homebrew
if [[ "$OSTYPE" == "darwin"* ]]; then
  if [[ -f "/opt/homebrew/bin/brew" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f "/usr/local/bin/brew" ]]; then
    export PATH="/usr/local/bin:$PATH"
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
fi

# Configure prompt
if [[ "$DOTFILES_SHELL_MODE" == "zsh-p10k" ]]; then
  [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
elif [[ "$DOTFILES_SHELL_MODE" == "zsh-starship" ]]; then
  export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
  if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
  fi
fi

if [[ -n "$TMUX" ]]; then
  export TERM=tmux-256color
else
  export TERM=xterm-256color
fi

# For Spin
[[ -f /opt/dev/dev.sh ]] && source /opt/dev/dev.sh

# zoxide -- smart directory navigation
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# fzf -- fuzzy finder (Ctrl+R history, Ctrl+T files)
if command -v fzf &> /dev/null; then
  eval "$(fzf --zsh)"
fi

# mise -- polyglot version manager (Ruby, Node, etc.)
# Must load AFTER brew shellenv, which calls path_helper and rebuilds PATH.
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# Worktrunk
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
