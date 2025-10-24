export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"

# Skip compaudit checks (safe for personal systems, saves ~300ms on startup)
skip_global_compinit=1

# alias sp="spf -c ~/.config/spf/config.toml"
alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Add Windows Node.js tools to PATH (for .exe wrappers) - DISABLED on WSL2 due to I/O errors
# export PATH="$PATH:/mnt/c/Program Files/nodejs"
# Use NVM-managed Node.js instead - it's already in PATH above

# openjdk
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# NPM Global - CRITICAL: DO NOT REMOVE OR MODIFY
# Uses user-writable directory for global npm packages (standard best practice)
# Avoids permission issues, prevents need for sudo, and works with nvm
# This ensures Claude Code and other global CLI tools are accessible without sudo
export PATH="$HOME/.npm-global/bin:$PATH"

# Dotnet cli through Windows (for direct access to Windows services)
alias dotnet='dotnet.exe'

# === DEVELOPMENT COMMANDS ===
#
alias npm3001="PORT=3001 npm run dev"
alias npm3002="PORT=3002 npm run dev"
alias npm3003="PORT=3003 npm run dev"

alias kill3000='echo "Searching for and forcefully terminating processes on port 3000..."; lsof -i :3000 -t | xargs -r kill -9; if [ $? -eq 0 ]; then echo "Processes on port 3000 terminated successfully (if any were found)."; else echo "An error occurred while trying to terminate processes on port 3000."; fi'
alias kill3001='echo "Searching for and forcefully terminating processes on port 3001..."; lsof -i :3001 -t | xargs -r kill -9; if [ $? -eq 0 ]; then echo "Processes on port 3001 terminated successfully (if any were found)."; else echo "An error occurred while trying to terminate processes on port 3001."; fi'
alias kill3002='echo "Searching for and forcefully terminating processes on port 3002..."; lsof -i :3002 -t | xargs -r kill -9; if [ $? -eq 0 ]; then echo "Processes on port 3002 terminated successfully (if any were found)."; else echo "An error occurred while trying to terminate processes on port 3002."; fi'
alias kill3003='echo "Searching for and forcefully terminating processes on port 3003..."; lsof -i :3003 -t | xargs -r kill -9; if [ $? -eq 0 ]; then echo "Processes on port 3003 terminated successfully (if any were found)."; else echo "An error occurred while trying to terminate processes on port 3003."; fi'
alias kill5555='echo "Searching for and forcefully terminating processes on port 5555..."; lsof -i :5555 -t | xargs -r kill -9; if [ $? -eq 0 ]; then echo "Processes on port 5555 terminated successfully (if any were found)."; else echo "An error occurred while trying to terminate processes on port 5555."; fi'

alias 3000="kill3000 && npm run dev"
alias 3001="kill3001 && npm3001"
alias 3002="kill3002 && npm3002"
alias 3003="kill3003 && npm3003"
alias 5555="kill5555 && npx prisma studio"

alias killnpmall="for port in 3000 3001 3002; do echo 'Attempting to forcefully kill processes on port $port...'; lsof -i :$port -t | xargs -r kill -9; done; echo 'Done.'"

alias script-export="DEBUG_CV_UPLOAD=true NODE_ENV=development npx tsx scripts/analyze-direct-upload.ts"

alias glab='glab.exe'

# Phoenix project shortcuts
alias devserver='cd ~/Dev/server'

dev() {
  cd ~/Dev/server
  echo ""
  echo "📁 You're in: $(pwd)"
  echo ""
  echo "🚀 Next steps (run in Windows PowerShell):"
  echo "   Backend:   cd C:\\Dev\\server\\Phoenix\\server\\Phoenix && dotnet run"
  echo "   Frontend:  cd C:\\Dev\\server\\Phoenix\\client\\phoenix-client && yarn dev"
  echo ""
  echo "📝 Git commands (run here in WSL2):"
  echo "   git status"
  echo "   git add ."
  echo "   git commit -m 'message'"
  echo ""
}

# === ==================== ===

ZSH_THEME="af-magic"

plugins=(git)

# Source Oh My Zsh after setting up other things for better performance
source $ZSH/oh-my-zsh.sh

alias tm='task-master'
# alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist' # Disabled on WSL2

bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[1;5C' forward-word      # Ctrl+Right
bindkey '^W' backward-kill-word     # Ctrl+W (usually default)
bindkey '^[d' kill-word             # Alt+d (delete word forward)

# Lazy-load completion system on first use
autoload -Uz compinit
_load_completion() {
    compinit
    unfunction _load_completion
}
compdef _load_completion
# Trigger completion loading on first command completion
zstyle ':completion:*' use-cache on

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

# Fix for Oh My Zsh NVM completion errors - remove cached functions
_omz_nvm_setup_completion() { return 0; }
_omz_nvm_setup_autoload() { return 0; }

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Only eval brew shellenv if the directory exists (fixes WSL2 I/O errors)
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)" || true
fi
