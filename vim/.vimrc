syntax on
filetype plugin indent on
set number
set relativenumber
set tabstop=4
set shiftwidth=4
set expandtab
set hlsearch
set ignorecase

call plug#begin('~/.vim/plugged')

Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

call plug#end()

let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode

autocmd VimLeave * silent !echo -ne "\e[6 q"

set clipboard=unnamed
set timeoutlen=1000 ttimeoutlen=0

set termguicolors
colorscheme catppuccin-latte
hi Normal guibg=NONE ctermbg=NONE
