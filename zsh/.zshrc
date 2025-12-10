export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"

# Skip compaudit checks (safe for personal systems, saves ~300ms on startup)
skip_global_compinit=1
# Disable OMZ auto-update prompt
DISABLE_AUTO_UPDATE=true
# Disable magic functions (slow on WSL2)
DISABLE_MAGIC_FUNCTIONS=true

# alias sp="spf -c ~/.config/spf/config.toml"
alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# openjdk
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# Windows tools PATH (Git, VS Code, dotnet, etc)
export PATH="/mnt/c/Program Files/Git/cmd:/mnt/c/Users/FilipM/AppData/Local/Programs/Microsoft VS Code:$PATH"

# Dotnet cli through Windows (for direct access to Windows services)
alias dotnet='dotnet.exe'

# Git through Windows (for corporate network access)
alias git='git.exe'
alias glab='glab.exe'

# VS Code through Windows
alias code='code.exe &'

# === ==================== ===

ZSH_THEME="af-magic"

plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Worktree navigation: cd @<worktree>/s or /c (after OMZ so compdef is available)
source "$HOME/.dotfiles/zsh/worktree-nav.zsh"

alias tm='task-master'
# alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist' # Disabled on WSL2

bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^W' backward-kill-word     # Ctrl+W (usually default)
bindkey '^[d' kill-word             # Alt+d (delete word forward)

spf() {
    os=$(uname -s)

    if [[ "$os" == "Darwin" ]]; then
        export SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
    fi

    command spf "$@"

    [ ! -f "$SPF_LAST_DIR" ] || {
        . "$SPF_LAST_DIR"
        rm -f -- "$SPF_LAST_DIR" > /dev/null
    }
}


# Lazy load NVM - only load when node/npm/yarn/nvm command is used
export NVM_DIR="$HOME/.nvm"

# Lazy loading function for NVM
nvm_lazy_load() {
  unalias nvm node npm yarn 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Create command aliases that trigger lazy loading
alias nvm='nvm_lazy_load && nvm'
alias node='nvm_lazy_load && node'
alias npm='nvm_lazy_load && npm'
alias yarn='nvm_lazy_load && yarn'

# Claude Code - always use v20.19.5 (pinned version, independent of NVM)
# Avoids confusion when switching Node versions
# claude() {
#   /home/filip/.nvm/versions/node/v20.19.5/bin/claude "$@"
# }

# Fix for Oh My Zsh NVM completion errors - remove cached functions
_omz_nvm_setup_completion() { return 0; }
_omz_nvm_setup_autoload() { return 0; }

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Only eval brew shellenv if the directory exists (fixes WSL2 I/O errors)
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)" || true
fi
export PATH="$HOME/.local/bin:$PATH"
