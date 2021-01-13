#!/usr/bin/env bash

# Script used to update both MacOS and Linux (debian-based with apt-get)
# based systems.

if [[ "$OSTYPE" == "darwin"* ]] && command -v brew &> /dev/null; then
    brew update
    brew upgrade
elif [[ "$OSTYPE" == "linux-gnu"* ]] && command -v apt-get &> /dev/null; then
    #---------------------------------------------------------------------------
    # This is NOT a good idea. The password will be stored in the calling
    # bash instances history. Seems to be a very complicated process
    # to delete the last line from that history from within this script.
    #if [ "$#" -ne 1 ]; then
    #    echo "usage: give your sudo-passwd as the only argument to this script"
    #    echo "to update the system."
    #else
    #    export HISTIGNORE='*sudo -S*'
    #    echo "$1" | sudo -S -k apt-get update
    #    echo "$1" | sudo -S -k apt-get upgrade
    #fi
    #---------------------------------------------------------------------------
    sudo apt-get update
    sudo apt-get upgrade
fi

if [ -d "${HOME}/dotfiles" ]; then
    git -C "${HOME}/dotfiles" pull
fi
