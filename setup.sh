#!/usr/bin/env bash

# This script will setup the dotfiles and executables
# contained in this repository. It will symlink all
# dotfiles and all files inside the bin-directory
# to the users ~ -dir.

# It will overwrite any existing file, but attempt to make
# a backup of the original file if they exist. Symlinks
# are not backed up.

# It keeps 2 iterations of backups, but NOTE that it is
# a simple script with very little logic in it. This means
# that if the script is run twice, with no change to the
# original files, then both backups will be equal.

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE1: This script only deals with the actual dotfiles
# and executables. Directories, such as etc (vim) needs to
# be handled otherwise, manually for example!
#
# NOTE2: On most linux system symlink permissions
# don't matter. The actual permissions will be
# the ones that the target file has. So make sure
# the dotfiles in THIS directory has appropriate
# permissions and flags set.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# USAGE:
# Simply run
# ./setup.sh
# from inside the cloned repository.
#
# Copyright (C) 2020,2021 Daniel Korpela.
# Permission to copy and modify is hereby granted,
# free of charge and without warranty of any kind,
# to any person obtaining a copy of this script.


BACKUPDIR="${HOME}/.dotfiles_backup"


function check_create_dir {
    # Creates the directory passed as the first argument if it's
    # not already present in the file system. Exits with error code 1
    # if the directory could not be created.
    if [ ! -d "$1" ]; then
      mkdir $1
      if [ "$?" -eq 0 ]; then
          echo "Created \`$1\` $2"
          echo ""
      fi
    fi

    if [ ! -d "$1" ]; then
      echo "Could not create \`$1 $2\`"
      echo "Exiting with no changes!"
      exit 1
    fi
}


function backup_file {
    # Backup the file passed as argument if it is a file
    # and not a symlink. Backup is defined as moving the
    # file to the backup-directory (deleting the orig).

    if [ "$#" -ne 2 ]; then
        echo "function backup_file called with illegal num of parameters"
        exit 5
    fi

    local f=$1
    local backupdir=$2

    if [ -f "${HOME}/${f}" ] && [ ! -h "${HOME}/${f}" ]; then
        echo "Backing up ${HOME}/${f}..."

        # Backup the backup..
        [ -f "${backupdir}/${f}" ] && mv -v "${backupdir}/${f}" "${backupdir}/${f}.old"

        # Backup the original file
        mv -iv "${HOME}/${f}" "${backupdir}/${f}"

        if [ "$?" -eq 0 ] && [ -f "${backupdir}/${f}" ]; then
            echo "Backup created as (unless you got a prompt and selected n): \`${backupdir}/${f}\`"
        else
            echo ""
            echo "!! Something went wrong when trying to backup: \`${HOME}/${f}\` !!"
            echo "!! Exiting. You should investigate this issue! !!"
            exit 2
        fi
    fi
}


function symlink_file {
    # Creates a symlink from the file passed as argument to the
    # home directory. Overwrites the existing file.
    if [ "$#" -ne 1 ]; then
        echo "function symlink_file called with illegal num of parameters"
        exit 5
    fi

    local f=$1
    ln -sfnv "${PWD}/${f}" "${HOME}/${f}"
    if [ "$?" -eq 0 ] && [ ! -f "${HOME}/${f}" ]; then
        echo ""
        echo "!!! Something went wrong when trying            !!!"
        echo "!!! to create symlink:                          !!!"
        echo "!!! ${PWD}/${f} -> ${HOME}/${f} !!!"
        echo "!!! Exiting. You should investigate this issue! !!!"
        exit 3
    fi
}


function setup_dotfiles {
    # First attempts to backup all the dotfiles in the users home directory
    # with the same name as the dotfiles available in the current directory
    # this script is run from. After that attempts to symlink all the
    # dotfiles from the current dir to the users pwd.

    check_create_dir $BACKUPDIR "for backups!"

    echo "Backing up and symlinking dotfiles.."
    echo "------------------------------------"
    echo ""

    local f
    for f in .*; do
        if [ -f "$f" ]; then
            backup_file $f $BACKUPDIR

            # At this point the file does not exist in ~. => create symlink
            symlink_file $f
            echo ""
        fi
    done

    echo "Done!"
    echo "-----"
    echo ""
}


function setup_binfiles {
    # First attempts to backup all the executables in the users ~/bin directory
    # with the same name as the executables available in the $PWD/bin directory
    # this script is run from. After that attempts to symlink all the
    # dotfiles from the current executables dir to the users ~/bin -directory.

    # This function assumes that all files living inside the bin-directory
    # are executables, it is not tested for!

    check_create_dir "${HOME}/bin" "for executables!"
    check_create_dir "${BACKUPDIR}/bin" "for executables backups!"

    echo "Backing up and symlinking executables.."
    echo "---------------------------------------"
    echo ""

    local f
    for f in bin/*; do
        if [ -f "$f" ]; then
            backup_file $f $BACKUPDIR

            # At this point the file does not exist in ~/bin. => create symlink
            symlink_file $f
            echo ""
        fi
      done

     echo "Done!"
     echo "-----"
     echo ""
}


setup_dotfiles
setup_binfiles

echo "All done! Exiting!"
