#Clear the screen if there are no parent shells

if [ "$SHLVL" = 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
    [ -x /usr/bin/clear ] && /usr/bin/clear
fi
