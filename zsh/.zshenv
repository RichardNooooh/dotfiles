# Keep Omarchy's executable and user-tool paths without loading its Bash rc.
if [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]]; then
  source /usr/share/omarchy/default/bash/env-bootstrap
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export EDITOR=nvim
export GIT_EDITOR=nvim
export SUDO_EDITOR="$EDITOR"
export BROWSER="${BROWSER:-omarchy-launch-browser}"
export DOTFILES="$HOME/.dotfiles"
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
export CGO_ENABLED=1

export BAT_THEME=ansi
export MANROFFOPT=-c
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export STARSHIP_CONFIG="$HOME/.config/starship-zsh.toml"

if [[ -z ${LANG:-} ]]; then
  [[ -r /etc/locale.conf ]] && source /etc/locale.conf
  export LANG="${LANG:-C.UTF-8}"
  export LANG LANGUAGE LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
  export LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION
fi

typeset -U path PATH
