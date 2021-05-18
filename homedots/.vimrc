set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'easymotion/vim-easymotion'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-obsession'
Plugin 'flazz/vim-colorschemes'
Plugin 'gcmt/taboo.vim'
Plugin 'valloric/youcompleteme'
call vundle#end()
filetype plugin indent on

colorscheme gruvbox

set t_Co=256
set nu
set rnu
set incsearch
syntax on

" ----- REMAP -----

let mapleader=" "

noremap <leader>1 1gt
noremap <leader>2 2gt
noremap <leader>3 3gt
noremap <leader>4 4gt
noremap <leader>5 5gt
noremap <leader>6 6gt
noremap <leader>7 7gt
noremap <leader>8 8gt
noremap <leader>9 9gt

noremap <silent><C-Q> :quit<CR>
noremap <silent> <C-S> :update<CR>

map <leader>j <C-W>j
map <leader>k <C-W>k
map <leader>h <C-W>h
map <leader>l <C-W>l


