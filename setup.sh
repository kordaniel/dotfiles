#!/bin/bash

# This is an script to symlink all the dotfiles
# living in this directory to the users ~.
# It will create an backup of the existing files
# into the $BACKUPDIR, where 2 newest backups are
# kept. Should not be run as root.
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE1: This script only deals with the actual
# dotfiles. Directories, such as etc needs to
# be handled otherwise, manually for example!
#
# NOTE2: This script only checks that there exists
# an backup. So it may be that something goes wrong
# when trying to create a fresh backup, and the script
# will continue working, even if it failed to create
# a new backup of the current file.
#
# NOTE3: On most linux system symlink permissions
# don't matter. The actual permissions will be
# the ones that the target file has. So make sure
# the dotfiles in THIS directory has appropriate
# permissions.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
# USAGE:
# chmod u+x setup.sh <- should not be needed, git should handle
# ./setup.sh
#
# Copyright (C) 2020 Daniel Korpela.
# Permission to copy and modify is hereby granted,
# free of charge and without warranty of any kind,
# to any person obtaining a copy of this script.

BACKUPDIR=${HOME}/.dotfiles_backup

echo "Attempting to create symlinks"
echo "-----------------------------"
echo ""

if [ ! -d "$BACKUPDIR" ]; then
  mkdir $BACKUPDIR
  echo "Created $BACKUPDIR for backups!"
  echo ""
fi

if [ ! -d "$BACKUPDIR" ]; then
  echo "Could not create $BACKUPDIR for backups!"
  echo "Exiting with nothing done!"
  exit 1
fi

for f in .*; do
  if [[ -f $f ]]; then
    # Backup existing files if they exist
    if [[ -f ~/$f ]]; then
      echo "Backing up ~/${f}..."
      # Backup the backup..
      [[ -f ${BACKUPDIR}/${f} ]] && mv -v ${BACKUPDIR}/${f} ${BACKUPDIR}/${f}.old
      mv -iv ~/${f} ${BACKUPDIR}/${f}
    
      if [[ ${BACKUPDIR}/${f} ]]; then
        echo "Backup created as ${BACKUPDIR}/${f}"
      else
        echo ""
        echo "!! Something went wrong when backing up ~/$f !!"
        echo "!! Exiting. You should investigate this issue! !!"
        exit 1
      fi
    else
      echo "File ~/${f} not found, continuing!"
    fi
    
    # At this point the file does not exist in ~.
    # So we create an symlink and check that it exists.
    echo "Creating symlink..."
    ln -sfnv ${PWD}/${f} ~/${f}

    if [[ ! -f ~/${f} ]]; then
      echo ""
      echo "!!! Something went wrong when trying            !!!"
      echo "!!! to create symlink:                          !!!"
      echo "!!! ${PWD}/${f} ~/${f} !!!"
      echo "!!! Exiting. You should investigate this issue! !!!"
      exit 2
    fi

    echo "Done!"
    echo ""
  fi
done

[ ! -d "${HOME}/bin" ] && mkdir ${HOME}/bin

if [ -d "${HOME}/bin" ]; then
  [ ! -d ${BACKUPDIR}/bin ] && mkdir ${BACKUPDIR}/bin
  if [ ! -d ${BACKUPDIR}/bin ]; then
    echo "Could not create ${BACKUPDIR}/bin"
    echo "Exiting without linking bin-scripts"
    echo "You should investigate this issue!"
    exit 2
  fi

  for f in bin/*; do
    if [[ -f $f ]]; then
      # Backup existing files if they exist
      if [[ -f ${HOME}/${f} ]]; then
        echo "Backing up ${HOME}/${f}..."
        # Backup the backup..
        [[ -f ${BACKUPDIR}/${f} ]] && mv -v ${BACKUPDIR}/${f} ${BACKUPDIR}/${f}.old
        mv -iv ${HOME}/$f ${BACKUPDIR}/$f

        if [[ ${BACKUPDIR}/${f} ]]; then
          echo "Backup created as ${BACKUPDIR}/${f}"
        else
          echo ""
          echo "!! Something went wrong when backing up $HOME/$f !!"
          echo "!! Exiting. You should investigate this issue !!"
          exit 2
        fi
      else
        echo "File ${HOME}/${f} not found, continuing!"
      fi

      echo "Creating symlink..."
      ln -sfnv ${PWD}/${f} ${HOME}/${f}
    
      if [[ ! -f ${HOME}/${f} ]]; then
        echo ""
        echo "!!! Something went wrong when trying            !!!"
        echo "!!! to create symlink:                          !!!"
        echo "!!! ${PWD}/${f} ${HOME}/${f} !!!"
        echo "!!! Exiting. You should investigate this issure !!!"
        exit 2
      fi

      echo "Done!"
      echo ""
    fi
  done

else
  echo "${HOME}/bin does not exist and could not create it."
  echo "Exiting without linking bin-scripts.."
  exit 2
fi


echo "All done! Exiting!"
