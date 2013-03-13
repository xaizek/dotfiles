# ==============================================================================
# bash completion

# use bash-completion, if available
if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# ==============================================================================
# aliases and functions

# ------------------------------------------------------------------------------
# vim

# open console vim with disabled support of X-server and not loading plugins
alias v='vim -X --noplugin'

# open files in tags of already running instance of gvim; without arguments just
# runs new gvim
function g()
{
    if [ "$#" -gt "0" ]; then
        gvim --remote-tab-silent "$@"
    else
        gvim
    fi
}

# launch stand-alone instance of gvim
alias G='gvim'

# ------------------------------------------------------------------------------
# vim-like

# vim-like short form of the make command
alias mak='make'

# vi-like command to quit shell
alias :q='exit'

# ------------------------------------------------------------------------------
# git

# show repository status (staged/modified/untracked files)
alias gs='git status'

# stage changes in a file
alias ga='git add'

# show list of branches
alias gb='git branch'

# make a commit
alias gc='git commit -v'

# show differences between refs/tree/files
alias gd='git diff'

# show brief of differences between refs/tree/files
alias gds='git diff --stat'

# show cached (staged) differences between refs/tree/files
alias gdc='git diff --cached'

# show brief of cached (staged) differences between refs/tree/files
alias gdcs='git diff --cached --stat'

# checkout a branch/commit
alias go='git checkout'

# create and checkout a branch
alias gob='git checkout -b'

# show repository history using "hist" git alias
alias ghi='git hist'

# spawn detached gitk process showing all refs
alias gk='gitk --all&'

# merge previous branch into current forcing creation of a merge commit
alias merge='git merge --no-ff @{-1}'

# ------------------------------------------------------------------------------
# ls

# easier to understand ls command (filetype suffixes/colors/readable size)
alias ls='ls --classify --color=auto --human-readable'

# single character shortcut for ls command
alias l='ls'

# two characters shortcut for ls command with list form of output
alias ll='ls -l'

# ------------------------------------------------------------------------------
# various

# display sizes in output of the free command in megabytes
alias free='free -m'

# display sizes in output of the df command in human-readable format
alias df='df --human-readable'

# display calendar with monday as the first day of a week
alias cal='cal -m'

# don't print version information on launching gdb
alias gdb='gdb -q'

# start mutt in browser screen
alias mutt='mutt -y'

# ------------------------------------------------------------------------------

# ==============================================================================
# a command to view man page

# format and show man page in less
function showman()
{
    groff -Tascii -man "$1" | less
}

# set autocompletion type for showman function
complete -G '*.1' showman

# ==============================================================================
# bash behaviour configuration

# append to history file instead of overwriting it when shell exits
shopt -s histappend

# don't overwrite existing files on redirection (require >| instead of >)
set -o noclobber

# thread directory paths as arguments to an implicit cd command
shopt -s autocd

# automatically correct minor spelling errors in arguments of cd command
shopt -s cdspell

# ==============================================================================
# command-line prompt customization

# {vifm-parent-sign}{pwd}{user-type}{space}
export PS1='[\w]\$ '
if [ "x$INSIDE_VIFM" != "x" ]; then
    PS1="[V]$PS1"
fi

# ==============================================================================
# always print command prompt on a new line

# query terminal escape codes for default and red colors and for color reset
if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    color_error="$(/usr/bin/tput setab 1)$(/usr/bin/tput setaf 7)"
    color_error_off="$(/usr/bin/tput sgr0)"
fi

# check cursor position and add new line if we're not in the first column
function prompt-command()
{
    exec < /dev/tty
    local OLDSTTY=$(stty -g)
    stty raw -echo min 0
    echo -en "\033[6n" > /dev/tty && read -sdR CURPOS
    stty $OLDSTTY
    [[ ${CURPOS##*;} -gt 1 ]] && echo "${color_error}↵${color_error_off}"

    echo -en "\033k\033\\"
}

# set prompt-command() function to be executed prior to printing prompt
PROMPT_COMMAND=prompt-command

# ==============================================================================
# complete git aliases as if they were expanded

# wraps an alias to perform completion as if it was expanded
function make-completion-wrapper()
{
    local function_name="$2"
    local arg_count=$(($#-3))
    local comp_function_name="$1"
    shift 2
    local function="
function $function_name()
{
    ((COMP_CWORD+=$arg_count))
    COMP_WORDS=( "$@" \${COMP_WORDS[@]:1} )
    "$comp_function_name"
    return 0
}"
    eval "$function"
}

# registers completion wrapper for an alias
function register-completion-wrapper()
{
    local alias_name="$1"
    local alias_cmd="$2"

    make-completion-wrapper _git _git_${alias_name}_mine $alias_cmd
    complete -o bashdefault -o default -o nospace -F _git_${alias_name}_mine "$alias_name"
}

# call register-completion-wrapper() for each alias that starts with "git "
eval "$(alias -p | sed -ne 's/alias \([^=]\+\)='\''\(git [^ ]*\) *.*'\''/register-completion-wrapper '\''\1'\'' '\''\2'\''/p')"

# ==============================================================================
# load bash local settings for this machine

# source ~/.bashrc_local file if it exists
if [ -f ~/.bashrc_local ]; then
    source ~/.bashrc_local
fi

# ==============================================================================

# vim: set textwidth=80 syntax+=.autofold :
