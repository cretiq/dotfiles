#!/bin/bash

# Toggle Ranger keymaps between Voyager (JKLÖ) and Standard (HJKL)
# Voyager: copymap <LEFT> j, <RIGHT> ö, <UP> l, <DOWN> k
# Standard: copymap <LEFT> h, <RIGHT> l, <UP> k, <DOWN> j

RCCONF="${1:-$HOME/.config/ranger/rc.conf}"

if [ ! -f "$RCCONF" ]; then
    echo "Error: File not found at $RCCONF"
    exit 1
fi

if grep -q "^copymap <LEFT>     j$" "$RCCONF"; then
    # Voyager → Standard
    sed -i 's/^copymap <UP>       l$/copymap <UP>       k/' "$RCCONF"
    sed -i 's/^copymap <DOWN>     k$/copymap <DOWN>     j/' "$RCCONF"
    sed -i 's/^copymap <LEFT>     j$/copymap <LEFT>     h/' "$RCCONF"
    sed -i 's/^copymap <RIGHT>    ö$/copymap <RIGHT>    l/' "$RCCONF"
    echo "Ranger: Voyager → Standard"
else
    # Standard → Voyager
    sed -i 's/^copymap <UP>       k$/copymap <UP>       l/' "$RCCONF"
    sed -i 's/^copymap <DOWN>     j$/copymap <DOWN>     k/' "$RCCONF"
    sed -i 's/^copymap <LEFT>     h$/copymap <LEFT>     j/' "$RCCONF"
    sed -i 's/^copymap <RIGHT>    l$/copymap <RIGHT>    ö/' "$RCCONF"
    echo "Ranger: Standard → Voyager"
fi
