#if not running interactively, don't do anything
if [ ! -v PS1 ]; then
    return
fi

source ~/.bashrc

#enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    source /etc/bash_completion
fi

#completion for make seems to be broken, under Arch anyway
complete -f make

##determine the distro we're on
DISTRO=unknown

if   [ -e /etc/SuSE-release ]; then
    DISTRO=opensuse
elif [ -e /etc/arch-release ]; then
    DISTRO=arch
elif [ -e /etc/debian_version ]; then
    DISTRO=debian
fi

export DISTRO

#display the running command in the title
#solution courtesy of Gilles from superuser.com
function preexec() { :; }
function preexec_invoke()
{
    #if returning from the command, do nothing
    if [ -n "$COMP_LINE" ]; then
        return
    fi
    
    local this_command=`history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//g"`
    local curdir=${PWD}
    
    if [ "$curdir" == "$HOME" ]; then
        curdir="~"
    fi
    
    echo -ne $(build_title_string "${USER}@$(hostname -s):${curdir##*/} \$$this_command")
    preexec "$this_command"
}

if tput hs; then
    trap "preexec_invoke" DEBUG
fi

#add default flags and colors to less
export LESS="-Ri" # preserve color escapes, enable contextual case sensitivity in searches
export LESS_TERMCAP_mb=$(tput blink; tput setaf 6)
export LESS_TERMCAP_md=$(tput bold; tput setaf 1)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_se=$(tput sgr0)
export LESS_TERMCAP_so=$(tput setab 4; tput bold; tput setaf 2)
export LESS_TERMCAP_ue=$(tput sgr0)
export LESS_TERMCAP_us=$(tput bold; tput setaf 3)

##misc
#add ~/bin, /sbin, /usr/sbin to path
export PATH=~/bin:$PATH:/sbin:/usr/sbin

#set pager
export PAGER=less

#set default editor
editor=$EDITOR

if command -v vim >/dev/null; then
    editor=vim
elif command -v vi >/dev/null; then #some systems have vi but not vim
    editor=vi
elif command -v nano >/dev/null; then #if there's no vi/m then nano is a nice editor too
    editor=nano
else
    echo "Warning: no (sane) editor found on system"
fi

export EDITOR=$editor
unset editor

# include machine-specific configuration
if [ -e ~/.bash_profile-site ]; then
    source ~/.bash_profile-site
fi

##display some neat info on login
if [ ! -v DISABLE_LOGIN_INFO ]; then
    echo Welcome to $(tput bold)$(tput setaf 2)$(hostname --fqdn)$(tput sgr0)
    echo System uptime: $(tput bold)$(tput setaf 1)$(~/bin/uptime)$(tput sgr0)
    echo Users connected: $(tput bold)$(tput setaf 3)$(who -q | head -n 1 | sed 's/[ ][ ]*/, /g')$(tput sgr0)
    echo Language and encoding: $(tput bold)$(tput setaf 6)${LANG-unknown}$(tput sgr0)
    echo QOTD: $(tput bold)$(tput setaf 5)$(~/bin/qotd)$(tput sgr0)
    
    export DISABLE_LOGIN_INFO=1
fi

##run ssh-agent when logging in (if it exists)
if command -v ssh-agent > /dev/null; then
    function fixsshenv()
    {
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    }
    function addkey() { ssh-add $@; }
    
    export -f fixsshenv addkey
    
    #only run it if an agent hasn't been forwarded through ssh, and if it's not already running
    if [ ! -v SSH_AUTH_SOCK -a "$(psu | grep ssh-agent | grep -v grep | wc -l)" -eq 0 ]; then
        eval $(ssh-agent -s)
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
        fixsshenv
        
        spawnedAgent=1
    fi
    
    if [ ! -v SSH_AUTH_SOCK ]; then
        if [ -v SSH_AGENT_PID ]; then
            echo "$(tput setaf 1)Warning: SSH_AGENT_PID is defined but not SSH_AUTH_SOCK$(tput sgr0)"
        else
            fixsshenv
        fi
    elif [ ! -v spawnedAgent ]; then
        echo "Note: using existing SSH agent socket at $SSH_AUTH_SOCK"
        
        if [ ! "$SSH_AUTH_SOCK" == "$HOME/.ssh/agent.sock" ]; then
            ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
            fixsshenv
        fi
    fi
fi
