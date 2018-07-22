if [ "$SHLVL" -le 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
    [ -x /usr/bin/clear ] && /usr/bin/clear
    
    colors Goodbye
    
    #if we're the last login shell for this user
    if [ `who | grep -v tmux | grep $USER | wc -l` -eq 1 ]; then
        #then remove all keys from the ssh agent
        ssh-add -D
    fi
fi

echo -e "$(tput bold)$(tput setaf 0)SHLVL is now $(expr $SHLVL - 1)$(tput sgr0)"
