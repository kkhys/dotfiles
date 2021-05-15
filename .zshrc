# alias
alias ..='cd ..'
alias l='less'
alias la='ls -aF --color=auto'
alias lla='ls -alF --color=auto'
alias lal='ls -alF --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias l.='ls -d .[a-zA-Z]* --color=auto'
alias v="vim"
alias g="git"

# zsh-syntax-highlighting
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh-autosuggestious
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

    autoload -Uz compinit
    compinit
  fi
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# anyenv
eval "$(anyenv init -)"

# hub
function git(){hub "$@"}

# coreutils
export PATH="/usr/local/opt/coreutils/libexec/gnubin:$PATH"

# SDKMAN!
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/kh/.sdkman"
[[ -s "/Users/kh/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/kh/.sdkman/bin/sdkman-init.sh"
export PATH="/usr/local/sbin:$PATH"
