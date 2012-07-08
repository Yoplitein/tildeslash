#Yoplitein's exquisite ~/.bash_profile

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
HISTCONTROL=$HISTCONTROL${HISTCONTROL+:}ignoredups
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#My customizations
#Custom titlebar stuff
case $TERM in
    xterm*)
        SETTITLE='\[\033]0;\u@\h:\w\007\]'
        ;;
    *)
        SETTITLE=''
        ;;
esac

NORMAL_COLOR='\[$(tput sgr0)\]'
GREEN_COLOR='\[$(tput setaf 2)\]'
BLUE_COLOR='\[$(tput setaf 4)\]'
YELLOW_COLOR='\[$(tput setaf 3)\]'

export PS1="$SETTITLE$GREEN_COLOR\u$NORMAL_COLOR@$BLUE_COLOR\h$NORMAL_COLOR:$YELLOW_COLOR\W$NORMAL_COLOR \$"

#add ~/bin to path
export PATH=$PATH:~/bin

#disable history expansion (so ! doesn't have to be escaped)
set +H

#Awesome aliases!
alias ls='ls -A1 --color=auto'
alias lsl='ls -A1l --color=auto'
alias psa='ps -Ao user,pid,time,cmd'
alias cls='clear'
alias shlvl='echo SHLVL is $SHLVL'

#Makes man not prompt for section (stupid openSUSE behaviour)
alias man='env MAN_POSIXLY_CORRECT=true man'

#Colors are fun! wheee!!
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

#Display $SHLVL on exit
trap 'echo SHLVL is now $(expr $SHLVL - 1); exit' 0
