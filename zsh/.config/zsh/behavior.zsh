LISTMAX=200
zstyle ':completion:*:*:*:*:*' menu auto select=2 no=200
zstyle ':completion:*' matcher-list \
  'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' \
  'm:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-} r:|[._-]=* r:|=*'

(( ${+widgets[autosuggest-accept]} )) && bindkey -M viins '^Y' autosuggest-accept

# Initialize try only on first use and keep its generated code native to Zsh.
if (( ${+commands[try]} )); then
  try() {
    unfunction try
    eval "$(SHELL=/usr/bin/zsh command try init "$HOME/Work/tries")"
    try "$@"
  }
fi
