# alias
alias ..='cd ..'
alias ...='cd ../..'
alias l='less'

# alias ls='exa'
alias la='ls -aF'
alias ll='ls -l'
alias lla='ls -alF'
alias l.='ls -d .[a-zA-Z]*'
alias v="vim"
alias g="git"
alias dc='docker compose'
alias de='docker exec'
alias pn='pnpm'
alias b='bun'
alias cl='claude'
alias yolo='claude --dangerously-skip-permissions'

HISTFILE=$ZDOTDIR/.zsh-history
HISTSIZE=2000
SAVEHIST=2000

setopt inc_append_history
setopt share_history
setopt AUTO_CD
setopt AUTO_PARAM_KEYS

export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8

# bun completions
[ -s "/Users/kkhys/.bun/_bun" ] && source "/Users/kkhys/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
