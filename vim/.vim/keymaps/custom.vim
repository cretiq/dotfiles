" Custom JKLÖ key bindings for Vim
" This remaps navigation from HJKL to JKLÖ for alternative keyboard layouts

" Clear any existing mappings first
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

" Custom navigation mappings (JKLÖ instead of HJKL)
" j = left (was h)
" k = down (was j)
" l = up (was k)
" ö = right (was l)

nnoremap j h
nnoremap k j
nnoremap l k
nnoremap ö l

vnoremap j h
vnoremap k j
vnoremap l k
vnoremap ö l

onoremap j h
onoremap k j
onoremap l k
onoremap ö l

echo "Vim keymaps: Custom (JKLÖ) mode activated"