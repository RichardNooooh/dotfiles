# File system
if (( ${+commands[eza]} )); then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

if [[ $TERM == xterm-kitty ]]; then
  alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
else
  alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
fi
alias eff='$EDITOR "$(ff)"'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Editors and tools
alias vim='nvim'
alias v='nvim'
alias lg='lazygit'
alias a='omarchy-agent --inline'
alias c='opencode --auto'
alias cx='printf "\033[2J\033[3J\033[H" && claude --permission-mode bypassPermissions'
alias cy='codex -s danger-full-access -a never'
alias d='docker'
alias r='rails'
alias t='tmux attach || tmux new -s Work'
alias h='herdr'
alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
alias mup='MISE_MINIMUM_RELEASE_AGE=0 mise up'

# Git aliases are explicit instead of coming from the OMZ git plugin.
alias g='git'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
alias gcad='git commit -a --amend'

alias decompress='tar -xzf'
