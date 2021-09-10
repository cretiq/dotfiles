export ZSH=/home/quanta/.oh-my-zsh
export TERM=xterm-256color
export ZPLUG_HOME=${HOME}/.zplug

if [ -e /usr/share/terminfo/x/xterm-256color ]; then
        export TERM='xterm-256color'
else
        export TERM='xterm-color'
fi

ZSH_THEME="fwalch"

plugins=(
    zsh-autosuggestions
    compleat
    archlinux
    autojump
)


source ~/.zplug/init.zsh
zplug "djui/alias-tips"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug 'dracula/zsh', as:theme
source $ZSH/oh-my-zsh.sh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
