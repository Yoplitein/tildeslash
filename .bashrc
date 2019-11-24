if [ ! -v PS1 ]; then
    return
fi

##various shell options
#don't put duplicate lines/lines beginning with a space in history
HISTCONTROL=ignoreboth

#append to the history file, don't overwrite it
shopt -s histappend

#check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

#disable history expansion (so ! doesn't have to be escaped)
set +H

#disable (fucking) XON/XOFF (Ctrl+S/Ctrl+Q)
stty -ixon

#ditto when using nested tmux sessions (???)
stty stop undef

##aliases
#general aliases
alias ls='ls -A --color=auto'
alias lsl='ls -Ahl --color=auto'
alias ps='ps -o %cpu:4,%mem:4,nice:3,start:5,user:15,pid:5,cmd'
alias psa='ps -A'
alias cls='clear'
alias shlvl='echo SHLVL is $SHLVL'
alias tree='tree -aAC'
alias cata='cat -A'
alias less='less -Ri'
alias dirs='dirs -v'
alias where='command -V'
alias hexdump='hexdump -vC'
alias grep='grep --color=auto'
alias grepi='grep -i --color=auto'
alias egrep='grep -E --color=auto'
alias du='du -h'
alias df='df -h'

#stupid openSUSE behaviour fixes
alias man='MAN_POSIXLY_CORRECT=true man'
alias last='last -10'
alias lastb='lastb -10'

if command -v systemctl > /dev/null; then
    alias ctl='systemctl --user'
    alias jctl='journalctl --user'
fi

if command -v git >/dev/null; then
    alias diff='git diff --no-index'
fi

if [ "$DISTRO" == "arch" ]; then
    alias netstat='ss'
    alias pacman='pacman --color=auto'
    alias pacaur='pacaur --color=auto'
fi

##functions
#finds processes owned by specified user (default self)
function psu() { ps -u ${1-$USER}; }

#searches process list, including column names
function pss() { psa | grep -iE "($@|^%CPU)" | grep -v grep; }

#search files for a string in a directory
function search() { grep -nir "$1" ${2-.}; }

#you never know when you might want to quickly browse the current directory through a browser, or something
function httpserv() { python -m SimpleHTTPServer ${1-"8000"}; }

#prints all active connections (functionize'd for exportability to root shells)
function lsinet() { netstat -nepaA inet; }

#view all of a command's output in less
function readout() { $@ 2>&1 | less; }

# :3
function colors()
{
    local message=${@-"Colorful"}
    
    if ! command -v shuf >/dev/null; then
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
            if [ $((color % 2)) -eq 0 -a $((i % 2)) -eq 0 ]; then
                bold="$(tput bold)"
            elif [ $((color % 2)) -eq 1 -a $((i % 2)) -eq 1 ]; then
                bold="$(tput bold)"
            fi
            
            echo -ne "$bold$(tput setaf $color)$message$(tput sgr0) "
        done
        
        echo -ne "\b.\n    "
        
        if [ $i -eq 10 ]; then
            echo -e "\n"
            break
        fi
    done
}

##readline options
bind "set show-all-if-ambiguous on"
bind "set bell-style audible"
bind "set input-meta on"
bind "set convert-meta off"
bind "set output-meta on"
bind "set completion-query-items 50"
bind "set completion-ignore-case on"

##custom prompt stuff
#works around some tput shortcomings
function build_title_string()
{
    local titleStr
    
    case $TERM in
        screen)
            titleStr="\033]2$@\033\\\\"
            
            ;;
        xterm)
            local termType="xterm"
            
            if [ -z "$(tput tsl 2>/dev/null)" ]; then #certain distros' termcaps require xterm+sl, others are satisfied with xterm
                if [ -z "$(TERM=xterm+sl tput tsl 2>/dev/null)" ]; then
                    return
                else
                    termType="xterm+sl"
                fi
            fi
            
            titleStr="$(TERM=$termType tput tsl)$@$(TERM=$termType tput fsl)"
            
            ;;
        putty)
            titleStr="$(tput tsl)$@$(tput fsl)"
            
            ;;
        *)
            titleStr=""
            
            ;;
    esac
    
    echo -n $titleStr
}

NORMAL_COLOR="\[$(tput sgr0)\]"
RED_COLOR="\[$(tput setaf 1)\]"
GREEN_COLOR="\[$(tput setaf 2)\]"
YELLOW_COLOR="\[$(tput setaf 3)\]"
BLUE_COLOR="\[$(tput setaf 4)\]"
PURPLE_COLOR="\[$(tput setaf 5)\]"
CYAN_COLOR="\[$(tput setaf 6)\]"
BOLD_COLOR="\[$(tput bold)\]"
SETTITLE="\[$(build_title_string "\\u@\\h:\\w")\]"
PS1="$SETTITLE"

if [ ! -v TMUX ]; then
    PS1="$PS1$YELLOW_COLOR[\D{%H:%M:%S}]"
fi

export PS1="$PS1$GREEN_COLOR\u$BLUE_COLOR@$RED_COLOR\h$BOLD_COLOR$PURPLE_COLOR:$YELLOW_COLOR\W $RED_COLOR\$(err=\$?; if [ \$err -ne 0 ]; then echo \"\$err \"; fi)$CYAN_COLOR\$$NORMAL_COLOR"
unset SETTITLE NORMAL_COLOR RED_COLOR GREEN_COLOR YELLOW_COLOR BLUE_COLOR PURPLE_COLOR CYAN_COLOR BOLD_COLOR

##include completions on arch systems (possibly elsewhere?)
completionsDir=/usr/share/bash-completion/completions

if [ -d $completionsDir ]; then
    source $completionsDir/*
fi
