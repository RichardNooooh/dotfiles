[[ -o interactive ]] || return

# A long-lived tmux server can retain a directory inode after its path is
# replaced. Recover before mise or prompt hooks inspect the working directory.
if [[ $PWD != /* || ! -d $PWD ]]; then
  builtin cd "$HOME" || return
fi

ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
ZSH_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$ZSH_CACHE_DIR/completions" "$ZSH_STATE_DIR"

# Ghostty normally injects this only into directly spawned shells. Loading it
# here also covers tmux and exec zsh, and its own state guard makes this safe.
if (( ! ${+_ghostty_state} )); then
  if [[ -n ${GHOSTTY_RESOURCES_DIR:-} && -r $GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration ]]; then
    source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
  elif [[ ${TERM_PROGRAM:-} == ghostty && -r /usr/share/ghostty/shell-integration/zsh/ghostty-integration ]]; then
    source /usr/share/ghostty/shell-integration/zsh/ghostty-integration
  fi
fi

export ZSH="$ZSH_DATA_DIR/oh-my-zsh"
ZSH_THEME=""
ZSH_COMPDUMP="$ZSH_CACHE_DIR/zcompdump-${ZSH_VERSION}"
zstyle ':omz:update' mode disabled

HISTFILE="$ZSH_STATE_DIR/history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_FIND_NO_DUPS HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS
setopt NO_BEEP
unsetopt HASH_CMDS HASH_DIRS

KEYTIMEOUT=25
VI_MODE_SET_CURSOR=true
VI_MODE_CURSOR_NORMAL=2
VI_MODE_CURSOR_VISUAL=2
VI_MODE_CURSOR_INSERT=6
VI_MODE_CURSOR_OPPEND=4
MODE_INDICATOR=""
INSERT_MODE_INDICATOR=""
ZLE_RPROMPT_INDENT=0

zstyle ':omz:plugins:ssh-agent' agent-forwarding yes
zstyle ':omz:plugins:ssh-agent' quiet yes

# Deliberately omit OMZ's git plugin: the tracked aliases below are authoritative.
# OMZ's normal compinit also discovers package completions in /usr/share/zsh/site-functions.
plugins=(mise sudo ssh-agent vi-mode fzf)
if [[ -r $ZSH/oh-my-zsh.sh ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "Oh My Zsh is missing; run: zsh $ZSH_CONFIG_DIR/bootstrap.zsh"
fi

if [[ -r $ZSH_DATA_DIR/plugins/fzf-tab/fzf-tab.plugin.zsh ]]; then
  source "$ZSH_DATA_DIR/plugins/fzf-tab/fzf-tab.plugin.zsh"
fi

if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

source "$ZSH_CONFIG_DIR/aliases.zsh"
source "$ZSH_CONFIG_DIR/functions.zsh"
source "$ZSH_CONFIG_DIR/behavior.zsh"

if [[ ${TERM:-} != dumb ]] && (( ${+commands[starship]} )); then
  eval "$(starship init zsh)"
fi

# zsh-syntax-highlighting must be the final sourced plugin.
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
