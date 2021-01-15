#login shells
PATH="$PATH:~/bin"

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi
