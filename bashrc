# ==============================================================================
# sourcing guard begin
# prevents double sourcing from the profile

if [ -n "$BASHRC_IS_LOADED" ]; then
    return
fi
BASHRC_IS_LOADED=yes

# ==============================================================================
# profile is loaded check

if [ -z "$PROFILE_IS_LOADED" ]; then
    source ~/.profile
fi

# ==============================================================================
# bash completion

# use bash-completion or at least git-bash-completion
if [ "$OS" != Windows_NT ]; then
    completion_file='/etc/bash_completion'
    if [ ! -f "$completion_file" ]; then
        completion_file='/etc/profile.d/bash_completion.sh'
    fi
else
    completion_file="$HOME/bin/git-completion.bash"
fi

# use completion if available
if [ -f "$completion_file" ]; then
    source "$completion_file"
fi

# ==============================================================================
# aliases and functions

# ------------------------------------------------------------------------------
# vim

# open console vim with disabled support of X-server and not loading plugins
alias e='vim -X --noplugin'
alias v='e'

# open files in tabs of already running instance of gvim creating one if there
# is no running one; without arguments just runs new gvim
function g()
{
    if [ "$#" -eq "1" ]; then
        gvim "$@"
    elif [ "$#" -gt "1" ]; then
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

# vi-like commands to quit shell
alias q='exit'
alias :q='exit'

# ------------------------------------------------------------------------------
# git

# show repository status (staged/modified/untracked files)
# NOTE: this alias hides GhostScript program
alias gs='git status'

# stage changes in a file
alias ga='git add'

# show list of branches
alias gb='git branch'

# make a commit
alias gc='git commit -v'

# make a commit staging all changes in the working tree except untracked files
alias gca='git commit -a -v'

# show differences between refs/tree/files
alias gd='git diff'

# show differences between refs/tree/files ignoring whitespace changes
alias gdw='git diff -w'

# show word differences between refs/tree/files
alias gwd="git diff -w --word-diff \"--word-diff-regex=[]a-z0-9A-Z_['*/\\\"#-]+\""

# show brief of differences between refs/tree/files
alias gds='git diff --stat'

# show cached (staged) differences between refs/tree/files
alias gdc='git diff --cached'

# show cached (staged) differences between refs/tree/files ignoring whitespace
# changes
alias gdcw='git diff --cached -w'

# show word differences between cached (staged) refs/tree/files
alias gwdc="git diff --cached -w --word-diff \"--word-diff-regex=[]a-z0-9A-Z_['*/\\\"#-]+\""

# show brief of cached (staged) differences between refs/tree/files
alias gdcs='git diff --cached --stat'

# checkout a branch/commit
alias go='git checkout'

# create and checkout a branch
alias gob='git checkout -b'

# create tracking copy of a remote branch and switch to it
alias got='git checkout --track'

# show information about git object
alias gh='git show'

# show information about git object with some statistic
alias ghs='git show --stat'

# show repository history using "hist" git alias
alias ghi='git hist'

# spawn detached gitk process showing all refs
alias gk='gitk --all&'

# merge previous branch into current forcing creation of a merge commit
function merge()
{
    local topic_branch=$(basename $(git rev-parse --symbolic-full-name @{-1}))
    local current_branch=$(basename $(git rev-parse --symbolic-full-name HEAD))

    echo -e "\e[1;32m[ Merging \e[33m$topic_branch\e[32m into \e[33m$current_branch\e[32m ]\e[m"
    git merge --no-ff @{-1}
    print-command-status
}

# push current branch to a remote (origin by default)
function push()
{
    if [ "$#" -eq "0" ]; then
        local remote='origin'
    elif [ "$#" -gt "0" ]; then
        local remote="$1"
    else
        echo 'Usage: push [remote (default: origin)]'
    fi
    local branch="$(basename $(git rev-parse --symbolic-full-name HEAD))"

    echo -e "\e[1;32m[ Pushing changes to \e[33m$remote\e[32m/\e[33m$branch\e[32m ]\e[m"
    git push "$remote" "$branch"
    print-command-status
}

# pull current branch from a remote (default: parent if exists, origin
# otherwise)
function pull()
{
    if [ "$#" -eq "0" ]; then
        if git remote | grep parent -q; then
            local default_remote=parent
        else
            local default_remote=origin
        fi
        local remote="$default_remote"
    elif [ "$#" -eq "1" ]; then
        local remote="$1"
    else
        echo 'Usage: pull [remote (default: parent or origin)]'
    fi

    echo -e "\e[1;32m[ Pulling changes from the \e[33m$remote\e[32m repository ]\e[m"
    git pull --ff-only "$remote" "$(git rev-parse --symbolic-full-name HEAD)"
    print-command-status
}

# an utility function, which print success/fail message depending on exit code
# returned by previous command
function print-command-status()
{
    if [ $? -eq 0 ]; then
        echo -e "\e[1;32m[ SUCCESS ]\e[m"
    else
        echo -e "\e[1;31m[ ERROR ]\e[m"
    fi
}

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

# vi-like shorthand for the man command with proper completion
alias h='man'
complete -F _man h

# ------------------------------------------------------------------------------

# ==============================================================================
# a command to view man page

# format and show man page in less
function showman()
{
    groff -Tascii -man "$1" | less
}

# set autocompletion type for showman function
complete -o dirnames -A file -X '!*.1' showman

# ==============================================================================
# bash behaviour configuration

# append to history file instead of overwriting it when shell exits
shopt -s histappend 2> /dev/null

# thread directory paths as arguments to an implicit cd command
shopt -s autocd 2> /dev/null

# automatically correct minor spelling errors in arguments of cd command
shopt -s cdspell 2> /dev/null

# don't overwrite existing files on redirection (require >| instead of >)
set -o noclobber

# the number of commands to remember in the command history
export HISTSIZE='100000'

# don't save duplicates, l, ll, ls, bf, bg, su and exit commands to command
# history
export HISTIGNORE='&:l:ll:ls:[bf]g:su:exit'

# remove all previous lines matching the current line from the history list
# before that line is saved
export HISTCONTROL='erasedups'

# ==============================================================================
# command-line prompt customization

# [{vifm-parent-sign}{parent-bash-shell-sign}*][{pwd}]{user-type}{space}
if [ -n "$PS1" ]; then
    export PS1="[\\w]\\$ "
    if [ "x$INSIDE_VIFM" != "x" -o "x$VIFM_SHELL" = x$(( SHLVL - 1 )) ]; then
        if [ "x$VIFM_SHELL" = x$(( SHLVL - 1 )) ]; then
            buf='V'
            for (( i = 0; i < SHLVL - VIFM_AT_SHELL; i++ )); do
                buf="${buf}b"
            done
            PS1="[$buf]$PS1"
        else
            PS1="[V]$PS1"
        fi
        if [ -z "$VIFM_AT_SHELL" ]; then
            export VIFM_AT_SHELL="$SHLVL"
        fi
        export VIFM_SHELL="$SHLVL"
        unset INSIDE_VIFM
    fi
else
    unset VIFM_SHELL
    unset VIFM_AT_SHELL
fi

# use light green to highlight the prompt
PS1="\\[\033[32m\\]$PS1\\[\033[0m\\]"

# ==============================================================================
# always print command prompt on a new line

if [ "$OS" != Windows_NT ]; then

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
    PROMPT_COMMAND='prompt-command'

fi

# ==============================================================================
# complete git aliases as if they were expanded

if command -v _git > /dev/null; then

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

fi

# ==============================================================================
# load bash local settings for this machine

# source ~/.bashrc_local file if it exists
if [ -f ~/.bashrc_local ]; then
    source ~/.bashrc_local
fi

# ==============================================================================
# sourcing guard end

unset BASHRC_IS_LOADED

# ==============================================================================

# vim: set filetype=sh textwidth=80 syntax+=.autofold :
