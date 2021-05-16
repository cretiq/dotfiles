set nocompatible              " be iMproved, required
filetype off                  " required

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'easymotion/vim-easymotion'
Plugin 'joshdick/onedark.vim'
Plugin 'dracula/vim'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-obsession'
Plugin 'flazz/vim-colorschemes'

call vundle#end()            " required
filetype plugin indent on    " required

set t_Co=256
colorscheme pablo

set nu
set rnu
set incsearch
set timeoutlen=0
syntax on
