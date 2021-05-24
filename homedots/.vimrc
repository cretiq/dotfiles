set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'easymotion/vim-easymotion'
Plugin 'scrooloose/syntastic'
Plugin 'tpope/vim-obsession'
Plugin 'scrooloose/nerdcommenter'
Plugin 'flazz/vim-colorschemes'
Plugin 'gcmt/taboo.vim'
Plugin 'valloric/youcompleteme'
Plugin 'Chiel92/vim-autoformat'
call vundle#end()
filetype plugin indent on

colorscheme adventurous
set background=dark

set t_Co=256
set nu
set rnu
set incsearch
set ignorecase
set expandtab
set shiftwidth=4
set autoindent
syntax on

set ttimeout
set ttimeoutlen=1
set timeoutlen=3000

" ----- REMAP -----

let mapleader=" "

" Set insert mode to a white beam
let &t_SI .= "\<esc>Ptmux;\<esc>\<esc>[6 q\<esc>\\"
let &t_SI .= "\<esc>Ptmux;\<esc>\<esc>]12;white\x7\<esc>\\"
" Set normal mode to a white block
let &t_EI .= "\<esc>Ptmux;\<esc>\<esc>[2 q\<esc>\\"
let &t_EI .= "\<esc>Ptmux;\<esc>\<esc>]12;white\x7\<esc>\\"
" Set replace mode to an white underscore
let &t_SR .= "\<esc>Ptmux;\<esc>\<esc>[4 q\<esc>\\"
let &t_SR .= "\<esc>Ptmux;\<esc>\<esc>]12;white\x7\<esc>\\"

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

function! s:ExtractThemeName(path)
    let split = split(a:path, "/")
    let theme_vim = split[6]
    let themeName_split = split(theme_vim, '\.')
    return themeName_split[0]
endfunction
    

function! SetNextTheme()
    let paths = split(globpath(&runtimepath, 'colors/*.vim'), "\n")
    if (exists('g:colors_name'))
        let current = g:colors_name
        let i = 0
        let themeName = ''
        for path in paths
            let themeName = s:ExtractThemeName(path)
            if (themeName == current)
                let nextTheme = s:ExtractThemeName(paths[i+1])
                echo nextTheme
                execute 'colorscheme 'nextTheme
                break
            endif
            let i += 1
        endfor
    endif
endfunction

function! SetRandomTheme()
    let paths = split(globpath(&runtimepath, 'colors/*.vim'), "\n")
    let themeLen = len(paths)
    let nr = reltime()[1] / 1008
    let setTheme = s:ExtractThemeName(paths[nr])
    echo setTheme
    execute 'colorscheme 'setTheme
endfunction


nnoremap <silent><F7> :call SetNextTheme()<CR>
nnoremap <silent><F6> :call SetRandomTheme()<CR>

