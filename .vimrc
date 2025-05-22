" =========================================== "
"           Common Vim Settings               "
"   These settings apply to ALL your computers"
" =========================================== "

" Use Vim defaults instead of Vi defaults
set nocompatible

" Enable syntax highlighting
syntax on

" Enable filetype detection (for syntax highlighting, indenting, etc.)
filetype plugin indent on

" Show absolute line numbers
set number

" Show relative line numbers (for easy jumping with j/k)
set relativenumber

" Basic indentation settings
set tabstop=4
set shiftwidth=4
set expandtab

" Better scrolling experience (optional)
set scrolloff=8


" =========================================== "
"         Machine/OS-Specific Settings        "
" =========================================== "

" Check if running on macOS
if has('mac')
    set guifont=JetBrains\ Mono:h14

    " Optional: Hostname-specific settings within macOS
    " Get the hostname without trailing newline
    let s:current_hostname = substitute(system('hostname'), '\n', '', 'g')

    if s:current_hostname == "Filips-MacBook-Pro-2.local" " <-- REPLACE with your actual Mac hostname
        " MacBook Pro Home
        echo "   -> Specific settings for 'my-macbook-pro' applied."
    elseif s:current_hostname == "Filips-MacBook-Pro-Dark.local" " <-- REPLACE with another Mac hostname
        " MacBook Pro Dark
        echo "   -> Specific settings for 'my-imac-home' applied."
    endif
endif


" =========================================== "
"           Plugin Management (vim-plug)      "
" =========================================== "

" Initialize vim-plug with the standard Vim plugin directory
call plug#begin('~/.vim/plugged')

" List of plugins
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
" Add other plugins below this line, e.g.:
" Plug 'tpope/vim-fugitive'
" Plug 'airblade/vim-gitgutter'
" Plug 'vim-airline/vim-airline'

" Initialize plugin system
call plug#end()


" =========================================== "
"                  Colorscheme                "
" =========================================== "

" Set the colorscheme (this will apply to all machines unless made conditional)
colorscheme catppuccin-macchiato

" Optional: If you wanted a different colorscheme per machine/OS:
" if has('mac')
"     colorscheme catppuccin-latte
" elseif has('unix')
"     colorscheme catppuccin-macchiato
" endif


" =========================================== "
"                  End of Config              "
" =========================================== "
