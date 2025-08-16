alias ..='cd ..'
alias ...='cd ../..'
alias l='less'
alias la='ls -aF'
alias ll='ls -l'
alias lla='ls -alF'
alias l.='ls -d .[a-zA-Z]*'
alias v="vim"
alias g="git"
alias dc='docker compose'
alias de='docker exec'
alias np='npm'
alias pn='pnpm'
alias b='bun'
alias cl='claude'
alias yolo='claude --dangerously-skip-permissions'

HISTFILE=$ZDOTDIR/.zsh-history
HISTSIZE=10000
SAVEHIST=10000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt AUTO_PARAM_KEYS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8

export PATH="/opt/homebrew/bin:$PATH"
