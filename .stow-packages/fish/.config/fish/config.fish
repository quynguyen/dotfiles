# Fish configuration for dotfiles
# Generated from Zsh configuration

echo "********************************************************************************"
echo "Loading custom Fish config"
echo "********************************************************************************"

# Set environment variables
set -gx DOTFILES_PATH "$HOME/dotfiles"
set -gx EDITOR (which nvim)
set -gx PAGER less
set -gx MANPAGER less
set -gx LESS -R
set -gx LESSOPEN "| (which src-hilite-lesspipe.sh) %s"

# Add custom bin directory to PATH
set -gx PATH "$HOME/.local/bin" "$HOME/.bin" $PATH

# Add Claude CLI path (fix for IDE integration after /migrate-installer)
set -gx PATH "$HOME/.claude/local/node_modules/.bin" $PATH

# Load Homebrew
if test (uname) = Darwin
    if test -f /opt/homebrew/bin/brew
        # Apple Silicon
        set -gx PATH /opt/homebrew/bin $PATH
        eval (/opt/homebrew/bin/brew shellenv)
    else if test -f /usr/local/bin/brew
        # Intel
        set -gx PATH /usr/local/bin $PATH
        eval (/usr/local/bin/brew shellenv)
    end
else
    # Linux
    if test -f "/home/linuxbrew/.linuxbrew/bin/brew"
        set -gx PATH "/home/linuxbrew/.linuxbrew/bin" $PATH
        eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
    end
end

# Navigation aliases
alias .. "cd .."
alias ... "cd ../.."
alias .... "cd ../../.."

# List commands
alias ls "ls --color=auto"
alias ll "ls -al"
alias l ll

# Application aliases
alias lg lazygit
alias cl clear
alias n nvim
alias cat bat
alias mux tmuxinator

# Git aliases
alias gs "git status"
alias gcm "git checkout main"
alias gpr "git pull --rebase"
alias log "git log --oneline --decorate --graph"

# Development aliases (Shopify-specific, can be customized)
alias dbp "dev cd business-platform"
alias dshop "dev cd shopify"
alias dweb "dev cd web"
alias dbo "dev cd bourgeois"
alias claude "~/.claude/local/claude"

# Fish-specific config editing aliases
alias nf "nvim ~/.config/fish/config.fish"
alias ef "exec fish"
alias python "python3"
alias pip "pip3"

# Platform-specific clipboard aliases
if test (uname) != Darwin
    if which xsel >/dev/null 2>&1
        alias pbcopy "xsel --clipboard --input"
        alias pbpaste "xsel --clipboard --output"
    else if which xclip >/dev/null 2>&1
        alias pbcopy "xclip -selection clipboard"
        alias pbpaste "xclip -selection clipboard -o"
    end
end

# Set TERM based on environment
if set -q TMUX
    set -gx TERM tmux-256color
else
    set -gx TERM xterm-256color
end

# NVM equivalent for Fish (if fisher plugin manager is available)
# Note: Fish has its own node version management approaches

# Starship prompt (will be used when in Fish mode)
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

echo "********************************************************************************"
echo "Initializing zoxide (smart directory navigation)"
echo "********************************************************************************"

# Initialize zoxide for smart directory navigation
if command -v zoxide >/dev/null 2>&1
    zoxide init fish | source
    echo "zoxide initialized - use 'z <dir>' to navigate quickly"
else
    echo "zoxide not found - install with: brew install zoxide"
end

# lf file manager integration - change directory on exit
function lfcd
    set tmp (mktemp)
    # `command` is needed in case `lfcd` is aliased to `lf`
    command lf -last-dir-path="$tmp" $argv
    if test -f "$tmp"
        set dir (cat "$tmp")
        rm -f "$tmp"
        if test -d "$dir"
            if test "$dir" != (pwd)
                cd "$dir"
            end
        end
    end
end

# Bind Ctrl+O to lfcd for quick file navigation
# Only set up bindings if we're in an interactive session
if status --is-interactive
    bind \co 'lfcd; commandline -f repaint'
end

# Alternative: create an alias 'd' for lfcd (like in Zsh)
alias d='lfcd'

# For Spin (Shopify development environment)
if test -f /opt/dev/dev.sh
    # Note: This is a bash script, might need Fish adaptation
    # source /opt/dev/dev.sh
end

echo "Fish configuration loaded successfully"


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Added by Antigravity
fish_add_path /Users/quy/.antigravity/antigravity/bin

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/homebrew/Caskroom/miniconda/base/bin/conda
    eval /opt/homebrew/Caskroom/miniconda/base/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
        . "/opt/homebrew/Caskroom/miniconda/base/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/homebrew/Caskroom/miniconda/base/bin" $PATH
    end
end
# <<< conda initialize <<<

