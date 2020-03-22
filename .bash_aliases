alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

alias ....='cd ../../..'
alias ...='cd ../..'
alias ..='cd ..'

alias ccat='highlight --out-format=ansi'

alias cman='man -Hlinks2'
alias melkki='ssh melkki.cs.helsinki.fi'
alias melkinpaasi='ssh melkinpaasi.cs.helsinki.fi'
alias melkinkari='ssh melkinkari.cs.helsinki.fi'
alias melkinphysics='ssh login.physics.helsinki.fi'

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
