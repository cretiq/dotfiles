export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"

# Skip compaudit checks (safe for personal systems, saves ~300ms on startup)
skip_global_compinit=1
# Disable OMZ auto-update prompt
DISABLE_AUTO_UPDATE=true
# Disable magic functions (slow on WSL2)
DISABLE_MAGIC_FUNCTIONS=true
# Ignore EOF (ctrl+d) so it doesn't close shell - allows ctrl+d in vim for page down
setopt IGNORE_EOF

# alias sp="spf -c ~/.config/spf/config.toml"
alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"
alias vim='nvim'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# openjdk (macOS only, harmless on WSL2)
# export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# ============================================================
# WINDOWS INTEROP (appendWindowsPath=false in wsl.conf)
# Only explicitly listed paths are available from WSL
# NOTE: PowerShell path causes input lag - use alias with full path instead
# ============================================================
WIN_PATHS=(
  "/mnt/c/Users/FilipM/scoop/shims"                  # glab.exe, other scoop tools
  "/mnt/c/Users/FilipM/AppData/Local/Programs/Microsoft VS Code"  # code.exe
)
export PATH="${(j.:.)WIN_PATHS}:$PATH"

# Ensure Linux-native binaries take priority (prevents WSL/Plan9 deadlocks)
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Windows tool aliases (use .exe versions for corporate network/services access)
# NOTE: git.exe removed - causes WSL kernel deadlocks via Plan9 filesystem crossings
alias dotnet='dotnet.exe'
alias glab='glab.exe'
alias code='code.exe &'
alias powershell='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
alias powershell.exe='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'

# Smart git wrapper: PowerShell on /mnt/c (avoids Plan9 deadlocks), native elsewhere
git() {
  if [[ "$PWD" == /mnt/c/* ]]; then
    powershell -Command "cd '$(wslpath -w .)' ; git $*"
  else
    command git "$@"
  fi
}
# ============================================================

# === ==================== ===

ZSH_THEME="af-magic"

plugins=(git)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Worktree navigation: cd @<worktree>/s or /c (after OMZ so compdef is available)
source "$HOME/.dotfiles/zsh/worktree-nav.zsh"

alias lg='lazygit'
# alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist' # Disabled on WSL2

bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^W' backward-kill-word     # Ctrl+W (usually default)
bindkey '^[d' kill-word             # Alt+d (delete word forward)

spf() {
    command spf "$@"
    # Handle lastdir on macOS
    local lastdir="$HOME/Library/Application Support/superfile/lastdir"
    [[ -f "$lastdir" ]] && { . "$lastdir"; rm -f -- "$lastdir"; }
}


# Lazy load NVM - only load when node/npm/yarn/nvm command is used
export NVM_DIR="$HOME/.nvm"

# Lazy loading function for NVM
nvm_lazy_load() {
  unalias nvm node npm npx yarn 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

# Create command aliases that trigger lazy loading
alias nvm='nvm_lazy_load && nvm'
alias node='nvm_lazy_load && node'
alias npm='nvm_lazy_load && npm'
alias npx='nvm_lazy_load && npx'
alias yarn='nvm_lazy_load && yarn'

# Claude Code - always use v20.19.5 (pinned version, independent of NVM)
# Avoids confusion when switching Node versions
# claude() {
#   /home/filip/.nvm/versions/node/v20.19.5/bin/claude "$@"
# }


# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Homebrew
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)" || true
fi

# Local bin takes priority (must be after brew)
export PATH="$HOME/.local/bin:$PATH"

# Claude Code aliases
alias c='claude'
alias cc='claude --continue'
alias cr='claude --resume'
alias ccc='cd ~/claude-scratch && claude'
alias ccca='cd ~/claude-scratch && claude /analysis:analyze-processes'
