#!/usr/bin/env bash

# This script is used to setup a fresh installation of either MacOS or
# a debian based Linux distribution using apt-get. For now this script
# has NOT been tested even once, so use at your OWN RISK! If all fails,
# then it's atleast a nice list of the needed software to have! :)
#
# Currently all it does is that it installs a few packages
# that I like to have on every machine I work on.

# Copyright (C) 2021 Daniel Korpela.
# Permission to copy and modify is hereby granted,
# free of charge and without warranty of any kind,
# to any person obtaining a copy of this script.


# Here we specify the Applications that are usually available trough apt-get.
# These all should be available on HomeBrew as well, but we prefer to use
# apt-get on Linux.
APPS=(
    "bash-completion"
    "git"
    "highlight"
    "htop"
    "python3"
    "sqlite"
    "tldr"
    "tmux"
    "valgrind"
    "wget"
)
# Applications that are only available on HomeBrew
APPS_BREW=( "bat" )


function install_homebrew {
    if ! command -v brew &> /dev/null; then
        echo "HomeBrew not found, installing!"
        # Updated on 16.1.2021 from https://brew.sh
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "HomeBrew found, running upgrade!"
        brew upgrade
    fi
}


function install_homebrew_packages {
    echo "Installing HomeBrew Packages"
    brew install "${APPS[@]}"
    brew install "${APPS_BREW[@]}"
}


function print_application_names {
    for app in "${@}"; do
            echo "$app"
    done
}


function install_aptget_packages {
    echo "Installing apt-get packages"
    local error_code=1 # We use 0 as true and 1 as false.

    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get upgrade
        if [ "$?" -eq 0 ]; then
            apt-get install "${APPS[@]}"
            echo "The following applications were not installed:"
            print_application_names "${APPS_BREW[@]}"
        else
            error_code=0
        fi
    else
        error_code=0
    fi

    if [ "$error_code" -eq 0 ]; then
        echo "Nothing was installed. This script requires a debian based system with \`apt-get\` installed."
        echo "Consider installing the following applications:"
        print_application_names "${APPS[@]}" "${APPS_BREW[@]}"
    fi
}


function install_on_macos {
    echo "It is better to install Xcode from the Appstore before running this \
script. This is due to the fact, that if you have Xcode installed then \
Homebrew can access the Xcode libraries since their licences should have \
been accepted."
    echo ""
    echo "So, if you think you will install Xcode at any time, it is better to \
do it before running this script. Should we continue?"
    echo ""

    read -p "Are you sure you want to continue? [y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[yY]$ ]]; then
        echo "Continuing installation!"
    else
        echo ""
        echo "Exiting with nothing done.. Hope to see you soon again!"
        exit 0
    fi

    echo "Installing Xcode command-line tools"
    xcode-select --install

    install_homebrew
    install_homebrew_packages
}


function install_on_debian {
    install_aptget_packages
}


# ---------------------------------- "MAIN" ------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    install_on_macos
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    install_on_debian
fi
