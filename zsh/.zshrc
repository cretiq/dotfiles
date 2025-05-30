export ZSH="$HOME/.oh-my-zsh"
export EDITOR="/usr/bin/vim"
export PATH="/Users/filipmellqvist/.nvm/versions/node/v21.6.0/bin:$PATH"

alias sp="spf -c ~/.config/spf/config.toml"

zstyle ':omz:plugins:nvm' lazy yes

ZSH_THEME="af-magic" 

plugins=(git nvm)

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

