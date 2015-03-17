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
# completion

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

# remove files with the following suffixes from completion matches
export FIGNORE='.d:.o'

# ==============================================================================
# aliases and functions

# ------------------------------------------------------------------------------
# vim

# open console vim
alias e='vim'
alias v='e'

# open vim and make it read error file from stdin
alias vimq='vim +cgetbuffer +bd! +cfirst -'

# open files in tabs of already running instance of gvim creating one if there
# is no running one; without arguments just runs new gvim
function g()
{
    if [ "$#" -eq "1" ]; then
        if [ -z "$(vim --serverlist)" ]; then
            run_detached_gvim "$@"
        else
            run_detached_gvim --remote-tab-silent "$@"
        fi
    elif [ "$#" -gt "1" ]; then
        run_detached_gvim --remote-tab-silent "$@"
    else
        run_detached_gvim
    fi
}

function run_detached_gvim()
{
    if [ "$OS" != Windows_NT ]; then
        gvim $VIMARGS "$@"
    else
        start gvim $VIMARGS "$@"
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
# NOTE: this function hides GhostScript program
function gs()
{
    local attr
    if [ "$OS" != Windows_NT -o "$OSTYPE" = cygwin ]; then
        attr='36'
    else
        attr='4;34'
    fi
    git -c color.status=always status --branch --short "$@" |
        sed "s/^#\\(#\\?[A-Za-z0-9 ()\"<>,.:'/-]*\\)/\x1b["$attr"m#\\1\x1b[0m/"
}

# same as gs() function, but does not show untracked files
function gsu()
{
    gs --untracked-files=no "$@"
}

# open tig with status window activated
alias ts='tig status'

# stage changes in a file
alias ga='git add'

# stage changes in a files under version control (no untracked files)
alias gu='git add -u'

# show list of branches
alias gb='git branch'

# make a commit
function gc()
{
    if [ "$(git branch | wc -l)" -gt 1 -a "$(branch)" = master ]; then
        echo -e "\e[1;33mContinue and commit to \e[1;${gmc}mmaster\e[m\e[1;33m?\e[m [y/N]"
        read -n1 answer
        echo

        if [ "$answer" != y ]; then
            return
        fi
    fi
    git commit -v "$@"
}

# make a commit staging all changes in the working tree except untracked files
alias gca='gc -a'

# show differences between refs/tree/files
alias gd='git diff --stat -u'

# show differences between refs/tree/files ignoring whitespace changes
alias gdw='git diff -w'

# show word differences between refs/tree/files
alias gwd="git diff -w --word-diff \"--word-diff-regex=[]a-z0-9A-Z_['*/\\\"{};().#-]+\""

# show brief of differences between refs/tree/files
alias gds='git diff --stat'

# show cached (staged) differences between refs/tree/files
alias gdc='git diff --cached'

# show cached (staged) differences between refs/tree/files ignoring whitespace
# changes
alias gdcw='git diff --cached -w'

# show word differences between cached (staged) refs/tree/files
alias gwdc="gwd --cached"

# show brief of cached (staged) differences between refs/tree/files
alias gdcs='git diff --cached --stat'

# checkout a branch/commit
alias go='git checkout'

# interactive version of switching to git branch
function igo()
{
    git branch |
        sed -e '/^\* /d' -e 's/^..//' |
        ( . sentaku -n
          _sf_set_header() { _s_header='Pick destination branch:'; }
          _sf_execute() { git checkout "${_s_inputs[$_s_current_n]}"; } &&
              _sf_main -H
        )
}

# interactive version opening one of files from git status omitting untracked
# ones
function igg()
{
    git status -s -uno |
        cut -d ' ' -f 3- |
        ( . sentaku -n
          _sf_set_header() { _s_header='Pick file to open:'; }
          _sf_execute() { g "${_s_inputs[$_s_current_n]}"; } && _sf_main -H
        )
}

# create and checkout a branch
alias gob='git checkout -b'

# create tracking copy of a remote branch and switch to it
alias got='git checkout --track'

# show information about git object
alias gh='git show -u --stat'

# show information about git object with some statistic
alias ghs='git show --stat'

# show first 100 of latest repository revisions using "hist" git alias
alias ghi='git hist -100'

# show full repository history using "hist" git alias
alias ghii='git hist'

# spawn detached gitk process showing all refs
alias gk='gitk --all&'

# git message color
gmc=36

# merge previous branch into current forcing creation of a merge commit
function merge()
{
    local topic_branch=$(basename $(git rev-parse --symbolic-full-name @{-1}))
    local current_branch=$(branch)

    echo -e "\e[1;${gmc}m[ Merging \e[33m$topic_branch\e[${gmc}m into \e[33m$current_branch\e[${gmc}m ]\e[m"
    git merge --no-ff @{-1}
    print-command-status
}

# outputs name of current git branch
function branch()
{
    basename $(git rev-parse --symbolic-full-name HEAD)
}

# fetch remote repository and update corresponding refs
function update()
{
    if [ $# -eq 0 ]; then
        if git remote | grep parent -q; then
            local default_remote=parent
        else
            local default_remote=origin
        fi
        local remote="$default_remote"
    elif [ $# -eq 1 ]; then
        local remote="$1"
    else
        echo 'Usage: update [remote (default: parent or origin)]'
        return 1
    fi

    echo -e "\e[1;${gmc}m[ Updating refs for \e[33m$remote\e[${gmc}m ]\e[m"
    git remote update "$remote"
    print-command-status
}

# rebase current branch on top of remove branch
function rrebase()
{
    if [ $# -gt 2 ]; then
        local remote="$2"
    fi
    if [ $# -gt 1 ]; then
        local branch="$1"
    fi

    if [ -z "$branch" ]; then
        local branch="develop"
    fi

    if [ -z "$remote" ]; then
        if git remote | grep parent -q; then
            local default_remote=parent
        else
            local default_remote=origin
        fi
        local remote="$default_remote"
    fi

    if [ -z "$branch" -o -z "$remote" ]; then
        echo 'Usage: rebase [branch (default: develop)] [remote (default: parent or origin)]'
        return 1
    fi

    echo -e "\e[1;${gmc}m[ Rebasing on \e[33m$remote\e[${gmc}m/\e[33m$branch\e[${gmc}m ]\e[m"
    git rebase "$remote"/"$branch"
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
        return 1
    fi
    local branch="$(basename $(git rev-parse --symbolic-full-name HEAD))"

    if [ -n "$FORCE_PUSH" ]; then
        extra_args="$extra_args -f"
    fi

    echo -e "\e[1;${gmc}m[ Pushing changes to \e[33m$remote\e[${gmc}m/\e[33m$branch\e[${gmc}m ]\e[m"
    git push $extra_args "$remote" "$branch"
    print-command-status
}

# same as push, but forces update
function pushf()
{
    echo "You're going to push remote branch with force.  Are you sure? [y/N]"
    read -n1 answer
    echo

    if [ x"$answer" = x"y" ]; then
        FORCE_PUSH=1 push
    fi
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
        return 1
    fi

    echo -e "\e[1;${gmc}m[ Pulling \e[33m$remote\e[${gmc}m/\e[33m$(b)\e[${gmc}m -> \e[33m$(b)\e[${gmc}m with \e[34mff\e[${gmc}m ]\e[m"
    git pull --ff-only "$remote" "$(git rev-parse --symbolic-full-name HEAD)"
    print-command-status
}

# an utility function, which print success/fail message depending on exit code
# returned by previous command
function print-command-status()
{
    if [ $? -eq 0 ]; then
        echo -e "\e[1;${gmc}m[ SUCCESS ]\e[m"
    else
        echo -e "\e[1;31m[ ERROR ]\e[m"
    fi
}

# ------------------------------------------------------------------------------
# ls

# easier to understand ls command (filetype suffixes/colors/readable size/
# directory grouping)
alias ls='ls --classify --color=auto --human-readable --group-directories-first'

# single character shortcut for ls command
alias l='ls'

# two characters shortcut for ls command with list form of output
alias ll='l -l'

# ls command that shows hidden files with list form of output
alias lla='ll -a'

# ls command with list form of output, but don't go into directory
alias lld='ll -d'

# ------------------------------------------------------------------------------
# various

# display sizes in output of the free command in megabytes and show totals
alias free='free -mt'

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

# format mount command output in a table
function mount()
{
    /bin/mount "$@" | column -t
}

# print content of $PATH environment variable one path per line
alias path='echo -e ${PATH//:/\\n}'

# resume wget by default
alias wget='wget -c'

# display ps entries that match regular expression
function pps()
{
    if [ $# -eq 0 ]; then
        echo 'Usage: pps args...'
        return 1
    fi

    local title=
    local lines=
    while read line; do
        if [ -z "$title" ]; then
            title="$line"
        else
            lines="$lines$line"$'\n'
        fi
    done < <(ps -elf)
    echo "$title"
    echo "$lines" | grep -v $$ | grep -i -e WCHAN -e "$@"
}

# connect to remote host via ssh and run/connect to "remote" tmux session there
function stmux()
{
    if [ $# -lt 1 ]; then
        echo 'Expected at least one argument' 1>&2
        return 1
    fi

    ssh "$@" 'tmux new-session -A -s remote'
}

# make a directory and cd into it
function mkcd()
{
    if [ $# -ne 1 ]; then
        echo 'Expected exactly one argument' 1>&2
        return 1
    fi

    mkdir -p "$1"
    cd "$1"
}

# ------------------------------------------------------------------------------

# ==============================================================================
# command customizations

# colorize the grep command output for ease of use
if [ "$OS" != Windows_NT -o "$OSTYPE" = cygwin ]; then
    export GREP_OPTIONS='--color=auto'
fi

# ==============================================================================
# a command to view man page

# format and show man page specified by the path rather than keyword
function showman()
{
    man "./$1"
}

# set autocompletion type for showman function
complete -o dirnames -A file -X '!*.@(1|man)' showman

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

# store timestamp along with commands in history
export HISTTIMEFORMAT='%F %T  '

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
if [ "$OS" = Windows_NT ]; then
    ps1attr='1;'
fi
if [ "$(tput colors 2> /dev/null)" -eq 256 ]; then
    PS1="\\[\033[1;38;5;228m\\]$PS1\\[\033[0m\\]"
else
    PS1="\\[\033[${ps1attr}32m\\]$PS1\\[\033[0m\\]"
fi

if [ -n "$SSH_CONNECTION" -a -z "$TMUX" ]; then
    PS1="[${HOSTNAME%%.*}]$PS1"
fi

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
        exec 100<&0
        exec < /dev/tty

        local OLDSTTY=$(stty -g)
        stty raw -echo min 0
        echo -en "\033[6n" > /dev/tty && read -sdR CURPOS
        stty $OLDSTTY
        [[ ${CURPOS##*;} -gt 1 ]] && echo "${color_error}↵${color_error_off}"

        # restore real stdout and close duplicate
        exec 0<&100 100<&-
    }

    # set prompt-command() function to be executed prior to printing prompt
    PROMPT_COMMAND="$PROMPT_COMMAND"$'\n''prompt-command'

fi

# ==============================================================================
# functions to query name of the current branch

# echoes full specification of the current branch
function B()
{
    local CUR_DIR="$PWD"
    while [ -n "$CUR_DIR" -a ! -d "${CUR_DIR}/.git" ]; do
        if [ "$CUR_DIR" = '/' ]; then
            break
        fi
        if [ "${CUR_DIR:1:3}" = ':/' -o "${CUR_DIR:1:3}" = ':' ]; then
            break
        fi

        CUR_DIR=${CUR_DIR%/*}
    done

    if [ -d "${CUR_DIR}/.git" ]; then
        local branch="$(<$CUR_DIR/.git/HEAD)"
        echo -n "${branch#*: }"
    fi
}

# echoes basename of the current branch
function b()
{
    echo -n "$(basename "$(B)")"
}

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
# terminal settings

# disable special meaning of Ctrl-S shortcut in the terminal
stty -ixon

# see `man gpg-agent` for details
if [ "$OS" != Windows_NT -o "$OSTYPE" = cygwin ]; then
    export GPG_TTY="$(tty)"
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
