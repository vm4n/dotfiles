#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

#export PATH="${PATH}:${HOME}/.local/bin/"

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi


# Customize to your needs...


# Import the colors.
#. "${HOME}/.cache/wal/colors.sh"
(cat /home/vman/.cache/wal/sequences &)

source  ~/.zprezto/modules/prompt/external/powerlevel9k/

~/bin/colorstest
~/bin/random-bash
