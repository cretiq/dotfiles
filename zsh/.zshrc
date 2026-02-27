export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"
export VISUAL="nvim"
alias v="nvim"
alias vim="nvim"

# alias sp="spf -c ~/.config/spf/config.toml"
alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"
alias r="ranger"
alias sz='source ~/.zshrc'

# Vim keymap shortcuts
alias vimkeys="~/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh"
alias vimtoggle="~/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh toggle"

# Ghostty appearance watcher (LaunchAgent management)
alias ghostty-watcher-load='ln -sf ~/.dotfiles/ghostty/scripts/com.filipmellqvist.ghostty-appearance.plist ~/Library/LaunchAgents/ && launchctl load ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist'
alias ghostty-watcher-unload='launchctl unload ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist && rm -f ~/Library/LaunchAgents/com.filipmellqvist.ghostty-appearance.plist'

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# openjdk
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

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
alias pdev="kill3000 && pnpm dev"
alias 3001="kill3001 && npm3001"
alias 3002="kill3002 && npm3002"
alias 3003="kill3003 && npm3003"
alias 5555="kill5555 && npx prisma studio"

alias killnpmall="for port in 3000 3001 3002; do echo 'Attempting to forcefully kill processes on port $port...'; lsof -i :$port -t | xargs -r kill -9; done; echo 'Done.'"

alias script-export="DEBUG_CV_UPLOAD=true NODE_ENV=development npx tsx scripts/analyze-direct-upload.ts"

# === ==================== ===

ZSH_THEME="macovsky"

plugins=(git)

source $ZSH/oh-my-zsh.sh

alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist'

# Claude Code aliases
alias c='claude'
alias cc='claude --continue'
alias cr='claude --resume'
alias ccc='cd ~/claude-scratch && claude'

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


# Lazy load NVM - only loads when node/npm/nvm/npx called (saves ~180ms startup)
export NVM_DIR="$HOME/.nvm"
nvm() {
  unset -f nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
  nvm "$@"
}
node() {
  unset -f nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  node "$@"
}
npm() {
  unset -f nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm "$@"
}
npx() {
  unset -f nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npx "$@"
}

# bun completions
[ -s "/Users/filipmellqvist/.bun/_bun" ] && source "/Users/filipmellqvist/.bun/_bun"

# Ghostty Tab Title Helper - Global Function
tt() {
    if [ $# -eq 0 ]; then
        # Auto-generate based on current directory and git branch
        local dir_name=$(basename "$(pwd)")
        local branch=""
        if git rev-parse --git-dir > /dev/null 2>&1; then
            branch=" ($(git branch --show-current 2>/dev/null))"
        fi
        local title="${dir_name}${branch}"
        printf "\033]0;%s\007" "$title"
        echo "Auto-set tab title: $title"
    else
        printf "\033]0;%s\007" "$*"
        echo "Tab title: $*"
    fi
}

# pnpm
export PNPM_HOME="/Users/filipmellqvist/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="$HOME/.local/bin:$PATH"

# Tauri code signing
export APPLE_SIGNING_IDENTITY="Apple Development: filip_mellqvist@msn.com (6KS7CT9WPG)"
