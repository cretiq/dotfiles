" Default HJKL key bindings for Vim
" This file restores standard Vim navigation

" Clear any existing custom mappings first
silent! unmap j
silent! unmap k
silent! unmap l
silent! unmap ö
silent! unmap h
silent! vunmap j
silent! vunmap k
silent! vunmap l
silent! vunmap ö
silent! vunmap h
silent! ounmap j
silent! ounmap k
silent! ounmap l
silent! ounmap ö
silent! ounmap h

" Restore default mappings explicitly
nnoremap h h
nnoremap j j
nnoremap k k
nnoremap l l

vnoremap h h
vnoremap j j
vnoremap k k
vnoremap l l

onoremap h h
onoremap j j
onoremap k k
onoremap l l

echo "Vim keymaps: Default (HJKL) mode activated"