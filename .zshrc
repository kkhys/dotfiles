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

# SDKMAN!
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="/Users/kh/.sdkman"
[[ -s "/Users/kh/.sdkman/bin/sdkman-init.sh" ]] && source "/Users/kh/.sdkman/bin/sdkman-init.sh"
export PATH="/usr/local/sbin:$PATH"
