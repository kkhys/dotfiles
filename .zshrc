alias ..='cd ..'
alias ...='cd ../..'
alias l='less'
alias ls='exa'
alias la='ls -aF'
alias ll='ls -l'
alias lla='ls -alF'
alias l.='ls -d .[a-zA-Z]*'
alias v="nvim"
alias g="git"
alias dc='docker compose'
alias de='docker exec'
alias t='tmux'
alias pn='pnpm'

HISTFILE=$ZDOTDIR/.zsh-history
HISTSIZE=2000
SAVEHIST=2000

setopt inc_append_history
setopt share_history
setopt AUTO_CD
setopt AUTO_PARAM_KEYS

export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

export LC_ALL=ja_JP.UTF-8
export LANG=ja_JP.UTF-8
export BAT_THEME="base16"

eval "$(sheldon source)"

function peco_history_selection() {
  BUFFER=`history -n 1 | tac | awk '!a[$0]++' | peco`
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N peco_history_selection
bindkey '^R' peco_history_selection

function find_cd() {
  local selected_dir=$(find . -type d | peco)
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
}
zle -N find_cd
bindkey '^X' find_cd
