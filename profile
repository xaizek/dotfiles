# ==============================================================================
# script load indicator

export PROFILE_IS_LOADED=yes

# ==============================================================================
# load bash configuration for this machine
# it is loaded at the very beginning to allow overwriting of its settings

# source ~/.bashrc file if it exists and we are actually using bash
if [ -f ~/.bashrc -a "$(basename $SHELL)" = bash ]; then
    . ~/.bashrc
fi

# ==============================================================================
# $PATH additions

# add ~/bin to $PATH
export PATH="$HOME/bin:$PATH"

# ==============================================================================
# less

# ignore case in search pattern unless it contains at least one uppercase letter
export LESS="$LESS -i"

# make less search for its binary configuration files at ~/.less on all
# platforms
export LESSKEY="$HOME/.less"

# ==============================================================================
# load profile local settings for this machine

# source ~/.profile_local file if it exists
if [ -f ~/.profile_local ]; then
    source ~/.profile_local
fi

# ==============================================================================

# vim: set filetype=sh textwidth=80 syntax+=.autofold :
