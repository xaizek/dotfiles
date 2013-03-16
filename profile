# ==============================================================================
# script load indicator

export PROFILE_IS_LOADED=yes

# ==============================================================================
# load bash configuration for this machine
# it is loaded at the very beginning to allow overwriting of its settings

# source ~/.bashrc file if it exists
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

# ==============================================================================
# $PATH additions

# add ~/bin to $PATH
export PATH="$HOME/bin:$PATH"

# ==============================================================================
# load profile local settings for this machine

# source ~/.profile_local file if it exists
if [ -f ~/.profile_local ]; then
    source ~/.profile_local
fi

# ==============================================================================

# vim: set filetype=sh textwidth=80 syntax+=.autofold :
