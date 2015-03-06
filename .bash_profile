###Yoplitein's exquisite ~/.bash_profile
#warning: may contain small amounts of command-line kung-fu

#if not running interactively, don't do anything
[ -z "$PS1" ] && return

##various shell options
#don't put duplicate lines/lines beginning with a space in history
HISTCONTROL=ignoreboth

#append to the history file, don't overwrite it
shopt -s histappend

#check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

#disable history expansion (so ! doesn't have to be escaped)
#(seriously, guys, arrow keys)
set +H

#disable (fucking) XON/XOFF (Ctrl+S/Ctrl+Q)
stty -ixon

#enable programmable completion features
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

#completion for make seems to be broken, under Arch anyway
complete -f make

#readline options
bind "set show-all-if-ambiguous on"
bind "set bell-style audible"
bind "set input-meta on"
bind "set convert-meta off"
bind "set output-meta on"
bind "set completion-query-items 50"
bind "set completion-ignore-case on"

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

##custom prompt stuff
#works around some tput shortcomings
function build_title_string()
{
    local titleStr
    
    case $TERM in
        screen) titleStr="\033]2$@\033\\\\";;
        xterm)
            local termType="xterm"
            
            if [ "$(tput tsl 2>/dev/null)" == "" ]; then #certain distros' termcaps require xterm+sl, others are satisfied with xterm
                if [ "$(TERM=xterm+sl tput tsl 2>/dev/null)" == "" ]; then
                    return;
                else
                    termType="xterm+sl"
                fi
            fi
            
            titleStr="$(TERM=$termType tput tsl)$@$(TERM=$termType tput fsl)";;
        putty) titleStr="$(tput tsl)$@$(tput fsl)";;
        *) titleStr="";;
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

if tput hs; then
    trap "preexec_invoke" DEBUG
fi

#sets the window's title
SETTITLE="\[$(build_title_string "\\u@\\h:\\w")\]"

#I love the fuck out of colors. Seriously.
NORMAL_COLOR="\[$(tput sgr0)\]"
RED_COLOR="\[$(tput setaf 1)\]"
GREEN_COLOR="\[$(tput setaf 2)\]"
YELLOW_COLOR="\[$(tput setaf 3)\]"
BLUE_COLOR="\[$(tput setaf 4)\]"
PURPLE_COLOR="\[$(tput setaf 5)\]"
CYAN_COLOR="\[$(tput setaf 6)\]"
BOLD_COLOR="\[$(tput bold)\]"

PS1="$SETTITLE"

if [ -z "$TMUX" ]; then
    PS1="$PS1$YELLOW_COLOR[\D{%H:%M:%S}]"
fi

export PS1="$PS1$GREEN_COLOR\u$RED_COLOR@$BLUE_COLOR\h$BOLD_COLOR$PURPLE_COLOR:$YELLOW_COLOR\W $RED_COLOR\$(err=\$?; if [ \$err -ne 0 ]; then echo \"\$err \"; fi)$CYAN_COLOR\$$NORMAL_COLOR"

#clean up a bit
unset SETTITLE NORMAL_COLOR RED_COLOR GREEN_COLOR YELLOW_COLOR BLUE_COLOR PURPLE_COLOR CYAN_COLOR BOLD_COLOR

#add colors to less
export LESS_TERMCAP_mb=$(tput blink; tput setaf 6)
export LESS_TERMCAP_md=$(tput bold; tput setaf 1)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_se=$(tput sgr0)
export LESS_TERMCAP_so=$(tput setab 4; tput bold; tput setaf 2)
export LESS_TERMCAP_ue=$(tput sgr0)
export LESS_TERMCAP_us=$(tput bold; tput setaf 3)
export GROFF_NO_SGR=yes #stupid openSUSE behaviour fix

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

##aliases and broken/stupid functionality fixes
#general aliases
alias ls='ls -A --color=auto'
alias lsl='ls -Ahl --color=auto'
alias ps='ps -o %cpu:4,%mem:4,nice:3,start:5,user:15,pid:5,cmd'
alias psa='ps -A'
alias cls='clear'
alias shlvl='echo SHLVL is $SHLVL'
alias tree='tree -aAC'
alias cata='cat -A'
alias less='less -R'
alias dm='dirman'
alias where='command -V'
alias hexdump='hexdump -vC'

#stupid openSUSE behaviour fixes
alias man='MAN_POSIXLY_CORRECT=true man'
alias last='last -10'
alias lastb='lastb -10'

#colors are fun! wheee!!
alias grep='grep --color=auto'
alias grepi='grep -i --color=auto'
alias egrep='grep -E --color=auto'

#I should have to pass arguments to specify non-human-readable, ffs
alias du='du -h'
alias df='df -h'

if [ "$DISTRO" == "arch" ]; then
    alias netstat='ss'
fi

##functions
#finds processes owned by specified user (default self)
function psu() { ps -u ${1-$USER}; }

#searches process list, including column names
function pss() { psa | grep -E "($@|%CPU)" | grep -v grep; }

#shell support for dirman
function dirman() { eval $(~/bin/dirman $@); }

#search files for a string in a directory
function search() { grep -nir "$1" ${2-.}; }

#you never know when you might want to quickly browse the current directory through a browser, or something
function httpserv() { python -m SimpleHTTPServer ${1-"8000"}; }

#prints all active connections (functionize'd for exportability to root shells)
function lsinet() { netstat -nepaA inet; }

#view all of a command's output in less
function readout() { $@ 2>&1 | less; }

#simple tmux wrapper that creates a session, if one doesn't exist, when attaching
if [ $(command -v tmux) ]; then
    function tmux()
    {
        local tmux=$(which tmux)
        
        if [[ $1 == at* ]]; then #attaching to a session
            if $tmux has-session 2>/dev/null; then
                $tmux at
            else
                $tmux new-session -d
                $tmux send-keys clear\;echo\ "Created new session." C-m
                $tmux at
            fi
        else
            $tmux $@
        fi
    }
fi

#exports
export -f httpserv lsinet

#execute site-specific configurations
if [ -e ~/.bashrc-site ]; then
    source ~/.bashrc-site
fi

##display some neat info on login
if [ "$DISABLE_LOGIN_INFO" == "" ]; then
    echo Welcome to $(tput bold)$(tput setaf 2)$(hostname --fqdn)$(tput sgr0)
    echo System uptime: $(tput bold)$(tput setaf 1)$(~/bin/uptime)$(tput sgr0)
    echo Users connected: $(tput bold)$(tput setaf 3)$(who -q | head -n 1 | sed 's/[ ][ ]*/, /g')$(tput sgr0)
    echo Language and encoding: $(tput bold)$(tput setaf 6)${LANG-unknown}$(tput sgr0)
    echo QOTD: $(tput bold)$(tput setaf 5)$(~/bin/qotd)$(tput sgr0)
    
    export DISABLE_LOGIN_INFO=1
fi

##run ssh-agent when logging in (if it exists)
if command -v ssh-agent > /dev/null; then
    #only run it when first logging in, and only if it's not already running
    if [ "$SHLVL" -eq "1" -a "$(psu | grep ssh-agent | grep -v grep | wc -l)" -eq "0" ]; then
        eval $(ssh-agent -s)
        
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
        
        function kill_agent()
        {
            ssh-agent -k > /dev/null 2>&1
            handle_logout
        }
        
        echo -n "$SSH_AGENT_PID" > ~/.ssh/agent.pid
        trap kill_agent EXIT
    fi
    
    function fixenv()
    {
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
        export SSH_AGENT_PID=$(cat ~/.ssh/agent.pid)
    }
    function addkey() { ssh-add $@; }
    
    export -f fixenv addkey
fi

#display an interesting logout message
function handle_logout()
{
    local message=${@-"Goodbye"}
    
    if [ $SHLVL -ne 1 ]; then
        if [ "$message" == "Goodbye" ]; then 
            return
        fi
    fi
    
    if [ ! $(command -v shuf) ]; then
        function shuf()
        {
            echo -e "1\n2\n3\n4\n5\n6"
        }
    fi
    
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
