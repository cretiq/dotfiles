export ZSH="$HOME/.oh-my-zsh"
export EDITOR="/usr/bin/vim"

# alias sp="spf -c ~/.config/spf/config.toml"
alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"

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

# === ==================== ===

ZSH_THEME="af-magic" 

plugins=(git)

source $ZSH/oh-my-zsh.sh

alias tm='task-master'
alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist'

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


# Load NVM manually (Oh My Zsh plugin removed due to completion errors)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Fix for Oh My Zsh NVM completion errors - remove cached functions
_omz_nvm_setup_completion() { return 0; }
_omz_nvm_setup_autoload() { return 0; }

# bun completions
[ -s "/Users/filipmellqvist/.bun/_bun" ] && source "/Users/filipmellqvist/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

alias claude="/Users/filipmellqvist/.claude/local/claude"
