export ZSH="$HOME/.oh-my-zsh"
export EDITOR="nvim"

# Skip compaudit checks (safe for personal systems, saves ~300ms on startup)
skip_global_compinit=1

# alias sp="spf -c ~/.config/spf/config.toml"
alias sp="spf -c ~/.spf.toml"
alias mw="macrowhisper"

# Vim keymap shortcuts
alias vimkeys="~/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh"
alias vimtoggle="~/.dotfiles/my_scripts/.script/vim-keymap-toggle.sh toggle"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

ZSH_THEME="af-magic"

plugins=(git)

# Source Oh My Zsh after setting up other things for better performance
source $ZSH/oh-my-zsh.sh

alias tm='task-master'
alias config='/usr/bin/git --git-dir=/Users/filipmellqvist/.dotfiles/ --work-tree=/Users/filipmellqvist'

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
[ -s "/Users/filipmellqvist/.bun/_bun" ] && source "/Users/filipmellqvist/.bun/_bun"
