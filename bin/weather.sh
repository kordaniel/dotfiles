#!/usr/bin/env bash

# Downloads the weather forecast in ASCII-format and prints
# out a nice looking weather forecast to the terminal.
# Adapts to the width of the terminal and prints more detailed
# forecasts in wider terminals.
#
# Uses the API at https://wttr.in
# API documentation: https://wttr.in/:help
#                    https://github.com/chubin/wttr.in
#
# Copyright (C) 2021 Daniel Korpela.
# Permission to copy and modify is hereby granted,
# free of charge and without warranty of any kind,
# to any person obtaining a copy of this script.

if ! command -v curl &> /dev/null; then
  echo '[ERROR]: this script requires that `curl` is installed in the system'
  exit 1
fi

BASE_URL="https://v2.wttr.in"
OPTIONS="AFM"
LOCATION='Helsinki'
LANGUAGE='en'

if [ "$#" -eq 0 ]; then
  echo "usage: $0 [Cityname] [language]"
  echo "No arguments given, using location \`$LOCATION\`"
  echo
else
  LOCATION=$1
  if [ "$#" -ge 2 ]; then
    LANGUAGE=$2
  fi
fi


REQ_TOOLS=("ps" "head" "tail" "stty" "grep" "cut" "tr")
REQ_MET=1

for t in ${REQ_TOOLS[@]}; do
  if ! command -v $t &> /dev/null; then
    echo "The command \`$t\` not found. Disabled adaptation to terminal width."
    REQ_MET=0
  fi
done


if [ "$REQ_MET" -eq 1 ]; then
  TERMINAL="$(ps h -p $$ -o tty | grep -v TTY)"
  TERMINALPATH="/dev/${TERMINAL}"
  # $TERMCOLS holds the number of columns in the current terminal
  TERMCOLS=$(stty -a < $TERMINALPATH | head -n1 | cut -f3 -d ";" | tr -dc "0-9")

  # V2 requires width of 74 for full forecast
  if [ "$TERMCOLS" -lt 74 ]; then
    BASE_URL="https://wttr.in"
    OPTIONS="format=%l:+%t+%c+(feels+like:+%f),+%w+%p\n&${OPTIONS}"
  fi
fi


COMMAND="curl -4 -s -S '${BASE_URL}/${LOCATION}?${OPTIONS}&lang=${LANGUAGE}'"
eval "$COMMAND"
