" Use Vim defaults instead of Vi defaults
set nocompatible

" Enable syntax highlighting
syntax on

" Enable filetype detection (for syntax highlighting, indenting, etc.)
filetype plugin indent on

" Show line numbers
set number

" Show relative line numbers
set relativenumber

set guifont=JetBrains\ Mono:h14

" ------------------------------------------- "

" Initialize vim-plug
call plug#begin('~/.vim/plugged')

" List of plugins
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

" Initialize plugin system
call plug#end()

" Colorscheme (must be after plug#end())
colorscheme catppuccin-macchiato

" ------------------------------------------- "
