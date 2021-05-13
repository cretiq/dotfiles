#tester
export ZSH="/home/qecs/.oh-my-zsh"
export TERM=xterm-256color
export wmount="/home/qecs/.config/own/mount.sh"
export EDITOR=subl
export USERNAME=filip_mellqvist@msn.com
export YOUR_GCS_BUCKET=catdetector
export PATH="$PATH:$NPM_PACKAGES/bin"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"
export XMLLINT_INDENT="    "
export PATH=~/.npm-global/bin:$PATH
export ZPLUG_HOME=${HOME}/.zplug



alias vifm="${HOME}/.vifm/scripts/vifmrun"
alias ss="sh /home/qecs/.script/pulseaudio_sink_switch.sh"
alias vims='(xseticon -id "$WINDOWID" /usr/share/pixmaps/vim-icon.png ; vim -S Session.vim)'
alias vimc="rm ~/.cache/vim/swap/*"
alias be='(cd ~/Documents/programming/maaj/maaj-app/ && npm run start)'
alias fe='(cd ~/Documents/programming/maaj/maaj-web/ && npm run start)'
alias nc='(konsole -e ncmatrix &); disown'
alias logi='(sh ~/.script/startup/logitech.sh)'
alias magic='(sudo sh ~/.script/startup/magickey.sh)'
alias magicc='(sudo sh ~/.script/startup/magickey_colemak_dh.sh)'
alias initcomp='( cd ~/.script/startup/ && sudo sh magickey.sh ; sh openbox.sh && sudo sh diskgrabber.sh ; sh vpn.sh  )'
alias inar='( cd ~/.script/startup/ && sudo sh magickey.sh ; sh openbox.sh && sudo sh diskgrabber.sh ; sh vpn.sh  )'
alias xcomp='(pkill xcompmgr && xcompmgr -r 30 -o .35 -f -l -30 -c -t -35 -D 2 -C &)'
alias screenoff='(sh ~/.script/miniscripts/screen_off.sh)'
alias start='(startx -- -dpi 120)'

NPM_PACKAGES="${HOME}/.npm-packages"

ZSH_THEME="fwalch"

plugins=(
    zsh-autosuggestions
    compleat
    archlinux
    zsh-syntax-highlighting
    autojump
)

if [ "$TERM" = "xterm-256color" ]; then xseticon -id "$WINDOWID" /usr/share/pixmaps/terminal256.png 
fi

source ~/.zplug/init.zsh
source /usr/share/nvm/init-nvm.sh
source $ZSH/oh-my-zsh.sh

#zplug "b4b4r07/enhancd", use:init.sh
#
## Install plugins if there are plugins that have not been installed
#if ! zplug check --verbose; then
#    printf "Install? [y/N]: "
#    if read -q; then
#        echo; zplug install
#    fi
#fi

