if [ "$SHLVL" -le 1 ]; then
    [ -x /usr/bin/clear_console ] && /usr/bin/clear_console -q
    [ -x /usr/bin/clear ] && /usr/bin/clear
    
    if [ -v spawnedAgent ]; then
        eval $(ssh-agent -k)
    fi
    
    colors Goodbye
fi

echo -e "$(tput bold)$(tput setaf 0)SHLVL is now $(expr $SHLVL - 1)$(tput sgr0)"
