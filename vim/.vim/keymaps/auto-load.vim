" Auto-load keymap based on saved state
" This file should be sourced from .vimrc

let s:vim_dir = expand('~/.dotfiles/vim/.vim')
let s:state_file = s:vim_dir . '/keymap_state'
let s:keymaps_dir = s:vim_dir . '/keymaps'

" Function to get current keymap state
function! GetKeymapState()
    if filereadable(s:state_file)
        return trim(readfile(s:state_file)[0])
    else
        return 'default'
    endif
endfunction

" Function to load appropriate keymap
function! LoadKeymap()
    let l:state = GetKeymapState()
    let l:keymap_file = s:keymaps_dir . '/' . l:state . '.vim'

    if filereadable(l:keymap_file)
        execute 'source ' . l:keymap_file
        return l:state
    else
        echo 'Keymap file not found: ' . l:keymap_file
        return 'unknown'
    endif
endfunction

" Function for status line
function! KeymapStatus()
    let l:state = GetKeymapState()
    if l:state == 'custom'
        return '[JKLÖ]'
    else
        return '[HJKL]'
    endif
endfunction

" Load keymap on startup
let g:current_keymap_mode = LoadKeymap()

" Add keymap status to status line if it's not already customized
if &statusline == ''
    set statusline=%f\ %m%r%h%w%=%{KeymapStatus()}\ %l,%c\ %p%%
endif