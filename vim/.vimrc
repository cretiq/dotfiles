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

" Cursor shape in iTerm2 and/or Mac Terminal?
"let &t_SI = "\<Esc>]50;CursorShape=1\x7" " Vertical bar in insert mode
"let &t_EI = "\<Esc>]50;CursorShape=0\x7" " Block in normal mode

" Cursor shape in Ghostty?
let &t_SI = "\e[6 q"    " Insert mode - vertical line
let &t_EI = "\e[2 q"    " Normal mode - block
let &t_SR = "\e[4 q"    " Replace mode - underline

autocmd VimLeave * silent !echo -ne "\e[6 q"

set guifont=JetBrains\ Mono:h15

set clipboard=unnamed
set timeoutlen=1000 ttimeoutlen=0

set termguicolors
colorscheme catppuccin-mocha
hi Normal guibg=NONE ctermbg=NONE

" Ghostty config syntax highlighting
autocmd BufRead,BufNewFile */ghostty/config set filetype=conf
autocmd BufRead,BufNewFile *.ghostty set filetype=conf
