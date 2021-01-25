# Set this to use custom username for ssh logins
#_SSH_USERNAME="<username>"

_SSH_COMMAND="ssh "

# Enable X11-forwarding if we have a X-server running
if [ ! -z ${DISPLAY+x} ]; then
    _SSH_COMMAND="${_SSH_COMMAND}-X "
fi

if [ ! -z ${_SSH_USERNAME+x} ]; then
    _SSH_COMMAND="${_SSH_COMMAND}${_SSH_USERNAME}@"
    unset _SSH_USERNAME
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias ....='cd ../../..'
alias ...='cd ../..'
alias ..='cd ..'

alias ccat='highlight --out-format=ansi'

alias cman='man -Hlinks2'

alias pangolin="${_SSH_COMMAND}pangolin.it.helsinki.fi"
alias markka="${_SSH_COMMAND}markka.it.helsinki.fi"
alias melkki="${_SSH_COMMAND}melkki.cs.helsinki.fi"
alias melkinpaasi="${_SSH_COMMAND}melkinpaasi.cs.helsinki.fi"
alias melkinkari="${_SSH_COMMAND}melkinkari.cs.helsinki.fi" # Old Cubbli 16.04 (03/2020)
#alias melkinphysics='ssh login.physics.helsinki.fi' #from ~March 2020 this is known as melkinkari.
alias pultti="${_SSH_COMMAND}pultti.it.helsinki.fi" # Larger physical machine with 256G Ram and Xeon E5-2620 6c/12t cpu
unset _SSH_COMMAND

# Subfunction needed by repeat().
_seq() {
  local lower upper output;
  lower=$1 upper=$2;

  if [ $lower -ge $upper ]; then return; fi
  while [ $lower -lt $upper ]; do
    echo -n "$lower "
    lower=$(($lower + 1))
  done
  echo $lower
}

# Repeat command. Use like:
#   repeat 10 echo foo
repeat() {
  local count="$1" i;
  shift;
  for i in $(_seq 1 "$count"); do
    eval "$@";
  done
}
