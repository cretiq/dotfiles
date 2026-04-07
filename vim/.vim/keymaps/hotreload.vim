" Hot-reload keymap system for real-time switching
" This file enables automatic keymap reloading when state changes

let s:vim_dir = expand('~/.dotfiles/vim/.vim')
let s:state_file = s:vim_dir . '/keymap_state'
let s:trigger_file = s:vim_dir . '/keymap_trigger'
let s:keymaps_dir = s:vim_dir . '/keymaps'

" Store the last known state to detect changes
if !exists('g:last_keymap_state')
    let g:last_keymap_state = ''
endif

" Function to reload keymap if state changed
function! CheckAndReloadKeymap()
    if filereadable(s:state_file)
        let l:current_state = trim(readfile(s:state_file)[0])

        " Only reload if state actually changed
        if l:current_state != g:last_keymap_state
            let l:keymap_file = s:keymaps_dir . '/' . l:current_state . '.vim'

            if filereadable(l:keymap_file)
                execute 'source ' . l:keymap_file
                let g:last_keymap_state = l:current_state

                " Visual feedback with highlight (skip during startup)
                if !exists('g:keymap_startup_mode')
                    if l:current_state == 'custom'
                        echohl WarningMsg | echo "🔄 Hot-reload: CUSTOM (JKLÖ) mode activated" | echohl None
                    else
                        echohl MoreMsg | echo "🔄 Hot-reload: DEFAULT (HJKL) mode activated" | echohl None
                    endif

                    " Force redraw to show status line changes
                    redraw!
                endif
            endif
        endif
    endif
endfunction

" Function to force reload keymap (triggered by external script)
function! ForceReloadKeymap()
    " Delete trigger file to acknowledge
    if filereadable(s:trigger_file)
        call delete(s:trigger_file)
    endif

    " Force reload by clearing cached state
    let g:last_keymap_state = ''
    call CheckAndReloadKeymap()
endfunction

" Set up autocommands for hot-reloading
augroup KeymapHotReload
    autocmd!
    " Check for state changes when gaining focus
    autocmd FocusGained * call CheckAndReloadKeymap()

    " Check for state changes periodically when cursor moves
    autocmd CursorHold * call CheckAndReloadKeymap()

    " Check for trigger file (created by external script)
    autocmd CursorHold * if filereadable(s:trigger_file) | call ForceReloadKeymap() | endif

    " Also check when entering/leaving insert mode
    autocmd InsertEnter * call CheckAndReloadKeymap()
augroup END

" Reduce CursorHold delay for more responsive reloading
set updatetime=1000

" Initial load
call CheckAndReloadKeymap()