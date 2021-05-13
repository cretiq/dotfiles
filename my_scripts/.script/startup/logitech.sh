my_mouse_id1=$(xinput | grep "Logitech G703 LS" | grep "(2)" | sed 's/^.*id=\([0-9]*\)[ \t].*$/\1/')
my_mouse_id2=$(xinput | grep "Logitech G903 LS" | grep "(2)" | sed 's/^.*id=\([0-9]*\)[ \t].*$/\1/')
my_mouse_id3=$(xinput | grep "Logitech G502" | grep "(2)" | sed 's/^.*id=\([0-9]*\)[ \t].*$/\1/')

mouse_found=false

if [ ${#my_mouse_id1} -gt 0 ]; then
	xinput set-prop $my_mouse_id1 154 0.900000, 0.000000, 0.000000, 0.000000, 0.900000, 0.000000, 0.000000, 0.000000, 1.000000
	mouse_found=true
	echo "> Logitech G703 set"
fi

if [ ${#my_mouse_id2} -gt 0 ]; then
	xinput set-prop $my_mouse_id2 154 0.350000, 0.000000, 0.000000, 0.000000, 0.350000, 0.000000, 0.000000, 0.000000, 1.000000
	mouse_found=true
	echo "> Logitech G903 set"
fi

if [ ${#my_mouse_id3} -gt 0 ]; then
	xinput set-prop $my_mouse_id3 154 0.350000, 0.000000, 0.000000, 0.000000, 0.350000, 0.000000, 0.000000, 0.000000, 1.000000
	mouse_found=true
	echo "> Logitech G502 set"
fi

if [ "$mouse_found" = false ]; then
	echo No Logitech mouse found...
fi
