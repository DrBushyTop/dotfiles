#!/bin/zsh

fzf-man-widget() {

  selected="echo {1} | cut -d '(' -f 1"
  batman="${selected} | xargs man | col -bx | bat --language=man --plain --color always"
  man -k . | sort \
  | awk -v cyan=$(tput setaf 6) -v blue=$(tput setaf 4) -v res=$(tput sgr0) -v bld=$(tput bold) '{ $1=cyan bld $1; $2=res blue;} 1' \
  | fzf  \
     -q "$1" \
     --ansi \
     --tiebreak=begin \
     --prompt=' man > '  \
     --preview-window '50%,rounded,<50(up,85%,border-bottom)' \
     --preview "${batman}" \
     --bind "enter:execute(${selected} | xargs man)" \
     --bind "ctrl-k:+change-preview(curl 'cht.sh/${selected}')+change-prompt(ﯽ cheat > )" \
     --bind "ctrl-m:+change-preview(${batman})+change-prompt( man > )" \
     --bind "ctrl-t:+change-preview(${selected} | xargs tldr)+change-prompt(ﳁ tldr > )"
  zle reset-prompt
}

zle -N fzf-man-widget

alias fman='fzf-man-widget'
