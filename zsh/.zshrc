export HOME="/home/qecs"
export ZSH="/home/qecs/.oh-my-zsh"
export TERM=xterm-256color
export wmount="/home/qecs/.config/own/mount.sh"
export EDITOR='vim'
export USERNAME=filip_mellqvist@msn.com
export YOUR_GCS_BUCKET=catdetector
export PATH="$PATH:$NPM_PACKAGES/bin"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"
export XMLLINT_INDENT="    "
export PATH=~/.npm-global/bin:$PATH
export ZPLUG_HOME=${HOME}/.zplug
export FZF_DEFAULT_OPTS="--layout=reverse --exact --inline-info"

alias vifm="/home/qecs/.vifm/scripts/vifmrun"
alias ss="sh /home/qecs/.script/pulseaudio_sink_switch.sh"
alias vims='(xseticon -id "$WINDOWID" /usr/share/pixmaps/vim-icon.png ; vim -S Session.vim)'
alias vimc="rm ~/.cache/vim/swap/*"
alias magic='(sudo sh ~/.script/startup/magickey.sh)'
alias magicc='(sudo sh ~/.script/startup/magickey_colemak_dh.sh)'
alias initcomp='( cd ~/.script/startup/ && sudo sh magickey.sh ; sh openbox.sh && sudo sh diskgrabber.sh ; sh vpn.sh  )'
alias inar='( cd ~/.script/startup/ && sudo sh magickey.sh ; sh openbox.sh && sudo sh diskgrabber.sh ; sh vpn.sh  )'
alias xcomp='(pkill xcompmgr && xcompmgr -r 30 -o .35 -f -l -30 -c -t -35 -D 2 -C &)'
alias screenoff='(sh ~/.script/miniscripts/screen_off.sh)'
alias start='(startx -- -dpi 120)'
alias help_keys='less ${HOME}/.script/help/keybindings.txt'
alias night='nordvpn set killswitch disabled && nordvpn d'

NPM_PACKAGES="/home/qecs/.npm-packages"

ZSH_THEME="fwalch"

plugins=(
    zsh-autosuggestions
    zsh-syntax-highlighting
    compleat
)

if [ "$TERM" = "xterm-256color" ]; then
    xseticon -id "$WINDOWID" /usr/share/pixmaps/terminal256.png
fi

source $ZSH/oh-my-zsh.sh
source $HOME/.zsh-vi-mode/zsh-vi-mode.plugin.zsh

function zvm_after_init() {
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
}
