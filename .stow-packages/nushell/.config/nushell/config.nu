# Nushell configuration for dotfiles
# Generated from Zsh configuration

print "********************************************************************************"
print "Loading custom Nushell config"
print "********************************************************************************"

# Environment variables
$env.DOTFILES_PATH = ($env.HOME | path join "dotfiles")
$env.EDITOR = (which nvim | get path | first)
$env.PAGER = "less"
$env.MANPAGER = "less"
$env.LESS = "-R"

# Add custom bin directory to PATH
$env.PATH = ($env.PATH | split row (char esep) | prepend ($env.HOME | path join ".bin"))

# Load Homebrew
if (sys host | get name) == "Darwin" {
    if ("/opt/homebrew/bin/brew" | path exists) {
        # Apple Silicon
        $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")
        # Note: Homebrew shellenv equivalent needs to be handled differently in Nushell
    } else if ("/usr/local/bin/brew" | path exists) {
        # Intel
        $env.PATH = ($env.PATH | prepend "/usr/local/bin")
    }
} else {
    # Linux
    if ("/home/linuxbrew/.linuxbrew/bin/brew" | path exists) {
        $env.PATH = ($env.PATH | prepend "/home/linuxbrew/.linuxbrew/bin")
    }
}

# Navigation aliases
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..

# List commands
alias ls = ls --color=auto
alias ll = ls -al
alias l = ll

# Application aliases
alias lg = lazygit
alias c = lf
alias cl = clear
alias n = nvim
alias cat = bat
alias mux = tmuxinator

# Git aliases
alias gs = git status
alias gcm = git checkout main
alias gpr = git pull --rebase
alias log = git log --oneline --decorate --graph

# Development aliases (Shopify-specific, can be customized)
alias dbp = dev cd business-platform
alias dshop = dev cd shopify
alias dweb = dev cd web
alias dbo = dev cd bourgeois

# Nushell-specific config editing aliases
alias nn = nvim ~/.config/nushell/config.nu
alias en = exec nu

# Platform-specific clipboard setup
if (sys host | get name) != "Darwin" {
    # Note: Nushell handles this differently, may need custom functions
}

# Set TERM based on environment
if ($env.TMUX? | is-not-empty) {
    $env.TERM = "tmux-256color"
} else {
    $env.TERM = "xterm-256color"
}

# Starship prompt (Nushell has built-in support)
if (which starship | is-not-empty) {
    $env.STARSHIP_SHELL = "nu"
    $env.STARSHIP_SESSION_KEY = (random chars -l 16)
    $env.PROMPT_MULTILINE_INDICATOR = (^starship prompt --continuation)
    $env.PROMPT_INDICATOR = ""
    $env.PROMPT_COMMAND = { ||
        # This is a simple example, actual implementation may vary
        ^starship prompt $"--status=($env.LAST_EXIT_CODE)" $"--cmd-duration=($env.CMD_DURATION_MS)"
    }
    $env.PROMPT_COMMAND_RIGHT = { ||
        ^starship prompt --right $"--status=($env.LAST_EXIT_CODE)" $"--cmd-duration=($env.CMD_DURATION_MS)"
    }
}

print "********************************************************************************"
print "Initializing zoxide (smart directory navigation)"
print "********************************************************************************"

# Initialize zoxide for smart directory navigation
if (which zoxide | is-not-empty) {
    # Note: Nushell zoxide integration may require different setup
    # For now, we'll add the basic hook
    $env.config = ($env.config | upsert hooks {
        pre_prompt: [{ ||
            if (which zoxide | is-not-empty) {
                ^zoxide add $env.PWD
            }
        }]
    })
    
    # Define z command as a custom command
    def z [path?: string] {
        if ($path | is-empty) {
            ^zoxide query --list
        } else {
            let result = (^zoxide query $path)
            cd $result
        }
    }
    
    # Define zi command for interactive selection
    def zi [path?: string] {
        if (which fzf | is-not-empty) {
            let selected = (^zoxide query --list | fzf)
            if ($selected | is-not-empty) {
                cd $selected
            }
        } else {
            print "fzf not found - install for interactive directory selection"
            z $path
        }
    }
    
    print "zoxide initialized - use 'z <dir>' to navigate quickly"
} else {
    print "zoxide not found - install with: brew install zoxide"
}

print "Nushell configuration loaded successfully"