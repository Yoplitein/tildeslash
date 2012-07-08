#Clear shit on log out so John Doe can't see where I store teh pr0n
#(can be circumvented in PuTTY by scrolling up, unfortunately.)
if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
    [ -x /usr/bin/clear ] && /usr/bin/clear
fi
