#!/bin/bash

# Toggle Obsidian vimrc between Voyager (JKLÖ) and Standard (HJKL)
# Voyager: has nnoremap j h (custom motion remaps)
# Standard: no motion remaps (default HJKL)

VIMRC="${1:-/mnt/c/Users/FilipM/Documents/Obsidian/RCO/.obsidian.vimrc}"

if [ ! -f "$VIMRC" ]; then
    echo "Error: File not found at $VIMRC"
    exit 1
fi

if grep -q "^nnoremap j h$" "$VIMRC"; then
    # Voyager → Standard: remove JKLÖ motion remaps
    sed -i '/^" Custom JKLÖ/d; /^" Physical keys:/d; /^" Normal mode/d; /^" Visual mode/d; /^" Operator pending/d' "$VIMRC"
    sed -i '/^[nvo]noremap j h$/d; /^[nvo]noremap k j$/d; /^[nvo]noremap l k$/d; /^[nvo]noremap ö l$/d' "$VIMRC"
    # Clean up blank lines at top
    sed -i '/./,$!d' "$VIMRC"
    echo "Obsidian: Voyager → Standard"
else
    # Standard → Voyager: prepend JKLÖ motion remaps
    TEMP_FILE="${VIMRC}.tmp"
    cat > "$TEMP_FILE" << 'HEADER'
" Custom JKLÖ navigation (direct motion mapping, no chaining)
" Physical keys: j=left, k=down, l=up, ö=right

" Normal mode - map directly to motions
nnoremap j h
nnoremap k j
nnoremap l k
nnoremap ö l

" Visual mode - map directly to motions
vnoremap j h
vnoremap k j
vnoremap l k
vnoremap ö l

" Operator pending mode - map directly to motions
onoremap j h
onoremap k j
onoremap l k
onoremap ö l

HEADER
    cat "$VIMRC" >> "$TEMP_FILE"
    mv "$TEMP_FILE" "$VIMRC"
    echo "Obsidian: Standard → Voyager"
fi
