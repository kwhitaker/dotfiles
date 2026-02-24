### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/home/kwhitaker/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Created by `pipx` on 2025-11-25 20:38:03
export PATH="$PATH:/home/kwhitaker/.local/bin"

# Add cargo/rust binaries to PATH
export PATH="$PATH:/home/kwhitaker/.cargo/bin"

# Auto complete
# History file location
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

# Save history incrementally and share between sessions
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Enable the built-in completion system
autoload -Uz compinit
compinit

# Source zsh-autosuggestions (suggests commands as you type based on history)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#555555'

# Source zsh-syntax-highlighting (highlights commands as valid/invalid)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Additional completion definitions
fpath=(/usr/share/zsh/site-functions $fpath)

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Menu selection for completions
zstyle ':completion:*' menu select

# Color completions
zstyle ':completion:*' list-colors ''

#Aliases
# File system
if command -v eza &> /dev/null; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
  alias cd="zd"
  zd() {
    if [ $# -eq 0 ]; then
      builtin cd ~ && return
    elif [ -d "$1" ]; then
      builtin cd "$1"
    else
      z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
    fi
  }
fi

open() {
  xdg-open "$@" >/dev/null 2>&1 &
}

eval "$(mise activate zsh)";

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Tools
alias d='docker'
alias r='rails'
n() { if [ "$#" -eq 0 ]; then nvim .; else nvim "$@"; fi; }

# Git
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

alias y='yazi'
alias cstart='pnpm start'
alias cui='pnpm start:ui'
alias cmsg='pnpm start:msg-worker'
alias ctmpl='dotnet watch --project ./src/Cartwheel.RazorTemplates.AspNetCore'
alias t='tmuxinator'

# wthrr alias
wthrr() {
  if [ -n "$1" ]; then
    # Location provided
    command wthrr -u f,mph -f w,d "$*"
  else
    # No location
    command wthrr -u f,mph -f w,d
  fi
}

alias oc="opencode"

# pnpm
export PNPM_HOME="/home/kwhitaker/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# DOTNET
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

# Starship prompt
eval "$(starship init zsh)"
