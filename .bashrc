#Yoplitein's exquisite ~/.bashrc
#warning: may contain small amounts of command-line kung-fu

#if not running interactively, don't do anything
[ -z "$PS1" ] && return

#don't put duplicate lines/lines beginning with a space in history
HISTCONTROL=ignoreboth

#append to the history file, don't overwrite it
shopt -s histappend

#check the window size after each command and, if necessary,
#update the values of LINES and COLUMNS.
shopt -s checkwinsize

#enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#custom titlebar stuff
function build_title_string()
{
    local titleStr
    
    case $TERM in
        xterm*|screen*) titleStr="\033]0;$@\007";;
        #screen*) titleStr="\033k\033$@\033\\";;
    esac
    
    echo -n $titleStr
}

#display the running command in the title
#solution courtesy of Gilles from superuser.com
function preexec() { :; }
function preexec_invoke()
{
    #if returning from the command, do nothing
    [ -n "$COMP_LINE" ] && return
    
    local this_command=`history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//g"`
    local curdir=${PWD}
    
    [ "$curdir" == "$HOME" ] && curdir="~"
    
    echo -ne $(build_title_string "${USER}@$(hostname -s):${curdir##*/} \$$this_command")
    preexec "$this_command"
}
trap "preexec_invoke" DEBUG

#sets the window's title
SETTITLE="\[$(build_title_string "\\u@\\h:\\w")"

case $TERM in
    xterm*|screen*) SETTITLE+="\]";;
    #screen*) SETTITLE+="\\\\]";; #\\\\\\\\ = \\?!
esac

#I love the fuck out of colors. Seriously.
NORMAL_COLOR='\[$(tput sgr0)\]'
RED_COLOR='\[$(tput setaf 1)\]'
GREEN_COLOR='\[$(tput setaf 2)\]'
YELLOW_COLOR='\[$(tput setaf 3)\]'
BLUE_COLOR='\[$(tput setaf 4)\]'
PURPLE_COLOR='\[$(tput setaf 5)\]'
CYAN_COLOR='\[$(tput setaf 6)\]'
BOLD_COLOR='\[$(tput bold)\]'

export PS1="$SETTITLE$YELLOW_COLOR[\D{%H:%M:%S}]$GREEN_COLOR\u$RED_COLOR@$BLUE_COLOR\h$BOLD_COLOR$PURPLE_COLOR:$YELLOW_COLOR\W $CYAN_COLOR\$$NORMAL_COLOR"

#clean up a bit
unset SETTITLE NORMAL_COLOR RED_COLOR GREEN_COLOR YELLOW_COLOR BLUE_COLOR PURPLE_COLOR CYAN_COLOR BOLD_COLOR

#misc
#add ~/bin to path
export PATH=$PATH:~/bin

#set default editor
editor=$EDITOR

if [ -e $(which vim 2>/dev/null) ]; then
    editor=vim
elif [ -e $(which vi 2>/dev/null) ]; then #some systems have vi but not vim
    editor=vi
elif [ -e $(which nano 2>/dev/null) ]; then #if there's no vi/m then nano is a nice editor too
    editor=nano
fi

export EDITOR=$editor
unset editor

#disable history expansion (so ! doesn't have to be escaped)
set +H

#disable XON/XOFF (Ctrl+S/Ctrl+Q)
stty -ixon

#aliases and broken/stupid functionality fixes
#general aliases
alias ls='ls -A1 --color=auto'
alias lsl='ls -A1l --color=auto'
alias psa='ps -Ao %cpu:4,%mem:4,start:5,user:15,pid:5,cmd'
alias cls='clear'
alias shlvl='echo SHLVL is $SHLVL'
alias tree='tree -aAC'
#alias screen='screen -A'
alias screens='tmux ls'
alias errlvl='echo $?'

#I should have to pass arguments to specify non-human-readable, ffs
alias du='du -h'
alias df='df -h'

#so I can screen -x after su'ing
function su() { chmod o+rw $SSH_TTY; $(which su) $@; chmod o-rw $SSH_TTY; }

#stupid openSUSE behavior fixes
alias man='env MAN_POSIXLY_CORRECT=true man'
alias sudo='env PATH=$PATH:/usr/sbin:/sbin sudo -E'
alias last='sudo last -10'
alias lastb='sudo lastb -10'

#colors are fun! wheee!!
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'

#sxecute site-specific configurations
if [ -e ~/.bashrc-site ]; then
    source ~/.bashrc-site
fi

#functions
#you never know when you might want to quickly browse the current directory through a browser, or something
function httpserv() { python -m SimpleHTTPServer ${1-"8000"}; }

#prints all active connections (functionize'd for exportability to root shells)
function lsinet() { netstat -nepaA inet; }

#exports
export -f httpserv lsinet

#this nests screen sessions to save layout across detatches
# function nestscreen()
# {
#     local name=${@-"nested"}
#     local innerName="inner"${name}
#     
#     screen -dmS "$innerName"
#     screen -S "$name" -c ~/.screenrc-container screen -x "$innerName"
# }

#login/logout info
#display some neat info on login
if [ "$LOGIN_INFO_SHOWN" == "" ]; then
    echo Welcome to $(tput bold)$(tput setaf 2)$(hostname --fqdn)$(tput sgr0)
    echo System uptime: $(tput bold)$(tput setaf 1)$(python ~/bin/uptime)$(tput sgr0)
    echo Users connected: $(tput bold)$(tput setaf 3)$(who -q | head -n 1 | sed 's/[ ][ ]*/, /g')$(tput sgr0)
    echo Language and encoding: $(tput bold)$(tput setaf 6)$LANG$(tput sgr0)
    echo QOTD: $(tput bold)$(tput setaf 5)$(python ~/bin/qotd)$(tput sgr0)
    
    export LOGIN_INFO_SHOWN=1
fi

#display an interesting logout message
function handle_logout()
{
    if [ "$SHLVL" != "1" ]; then
        return
    fi
    
    local message=${@-"Goodbye"}
    
    echo -ne "\n    "
    
    for i in {1..15}
    do
        for color in $(shuf -i 0-6 | sed 's/\n/ /g')
        do
            local bold=""
            
            #make every other word bold, alternate between lines
            if [ $(expr $color \% 2) == 0 ] && [ $(expr $i \% 2) == 0 ]; then
                bold="$(tput bold)"
            elif [ $(expr $color \% 2) == 1 ] && [ $(expr $i \% 2) == 1 ]; then
                bold="$(tput bold)"
            fi
            
            echo -ne "$bold$(tput setaf $color)$message$(tput sgr0) "
        done
        
        echo -ne "\b.\n    "
        
        if [ "$i" == "10" ]; then
            echo -e "\n"
            break
        fi
    done
    
    if [ "$message" == "Goodbye" ]; then
        #the CRs fix a bug where any text printed when exiting the shell will have its first character missing
        #(I have no idea why that happens, even after three hours of debugging)
        echo -e "\r\r\r\r\r"$(tput bold)$(tput setaf 0)"SHLVL is now $(expr $SHLVL - 1)"$(tput sgr0)
    fi
}
trap handle_logout EXIT

# :3
function colors() { handle_logout ${@-"Colorful"}; }
