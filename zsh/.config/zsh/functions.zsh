# File selection and launchers
sff() {
  (( $# )) || { print -u2 "Usage: sff <destination> (e.g. sff host:/tmp/)"; return 1; }
  local file
  file=$(find . -type f -printf '%T@\t%p\n' | sort -rn | cut -f2- | ff) &&
    [[ -n $file ]] && scp "$file" "$1"
}

open() {
  xdg-open "$@" >/dev/null 2>&1 &!
}

n() {
  if (( $# )); then
    command nvim "$@"
  else
    command nvim .
  fi
}

# Git worktrees
ga() {
  [[ -n ${1:-} ]] || { print -u2 "Usage: ga <branch name>"; return 1; }
  local branch="$1" base="${PWD:t}" wt_path
  wt_path="../${base}--${branch}"
  git worktree add -b "$branch" "$wt_path" || return
  mise trust "$wt_path" || return
  builtin cd "$wt_path"
}

gd() {
  gum confirm "Remove worktree and branch?" || return
  local cwd="$PWD" worktree="${PWD:t}" root branch
  root="${worktree%%--*}"
  branch="${worktree#*--}"
  [[ $root != $worktree ]] || return
  builtin cd "../$root" || return
  git worktree remove "$cwd" --force || return
  git branch -D "$branch"
}

# Tmux layouts
_tmux_start_pane_command() {
  local pane="$1" pane_command="$2" ready
  local -i attempts=0 ready_checks=0
  tmux select-pane -t "$pane" || return
  tmux send-keys -t "$pane" -l "$pane_command"
  tmux send-keys -t "$pane" C-m
  while (( attempts < 50 )); do
    ready=$(tmux display-message -p -t "$pane" '#{alternate_on}') || return
    (( ++attempts ))
    if [[ $ready == 1 ]]; then
      (( ++ready_checks ))
      (( ready_checks == 5 )) && return 0
    else
      ready_checks=0
    fi
    sleep 0.02
  done
}

tdl() {
  [[ -n ${1:-} ]] || { print -u2 "Usage: tdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -n ${TMUX:-} ]] || { print -u2 "You must start tmux to use tdl."; return 1; }
  local current_dir="$PWD" editor_pane="$TMUX_PANE" ai_pane ai2_pane
  local ai="$1" ai2="${2:-}"
  tmux rename-window -t "$editor_pane" "${current_dir:t}"
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}') || return
  tmux split-window -v -p 25 -t "$editor_pane" -c "$current_dir" || return
  if [[ -n $ai2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$current_dir" -P -F '#{pane_id}') || return
    _tmux_start_pane_command "$ai2_pane" "$ai2" || return
  fi
  _tmux_start_pane_command "$ai_pane" "$ai" || return
  tmux send-keys -t "$editor_pane" -l "$EDITOR ."
  tmux send-keys -t "$editor_pane" C-m
  tmux select-pane -t "$editor_pane"
}

tds() {
  (( $# == 0 )) || { print -u2 "Usage: tds"; return 1; }
  [[ -n ${TMUX:-} ]] || { print -u2 "You must start tmux to use tds."; return 1; }
  local current_dir="$PWD" editor_pane="$TMUX_PANE" diff_pane terminal_pane opencode_pane
  tmux rename-window -t "$editor_pane" "${current_dir:t}"
  terminal_pane=$(tmux split-window -v -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}') || return
  diff_pane=$(tmux split-window -h -p 50 -t "$editor_pane" -c "$current_dir" -P -F '#{pane_id}') || return
  opencode_pane=$(tmux split-window -h -p 50 -t "$terminal_pane" -c "$current_dir" -P -F '#{pane_id}') || return
  tmux send-keys -t "$editor_pane" -l "nvim ."
  tmux send-keys -t "$editor_pane" C-m
  tmux send-keys -t "$diff_pane" -l "hunk diff --watch"
  tmux send-keys -t "$diff_pane" C-m
  tmux send-keys -t "$opencode_pane" -l "opencode"
  tmux send-keys -t "$opencode_pane" C-m
  tmux select-pane -t "$editor_pane"
}

tdlm() {
  [[ -n ${1:-} ]] || { print -u2 "Usage: tdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -n ${TMUX:-} ]] || { print -u2 "You must start tmux to use tdlm."; return 1; }
  local ai="$1" ai2="${2:-}" base_dir="$PWD" dir dirpath pane_id command
  local first=1
  tmux rename-session "${${base_dir:t}//[.:]/-}"
  for dir in "$base_dir"/*(N/); do
    dirpath="${dir%/}"
    printf -v command 'builtin cd %q && tdl %q' "$dirpath" "$ai"
    [[ -n $ai2 ]] && printf -v command '%s %q' "$command" "$ai2"
    if (( first )); then
      tmux send-keys -t "$TMUX_PANE" "$command" C-m
      first=0
    else
      pane_id=$(tmux new-window -c "$dirpath" -P -F '#{pane_id}') || return
      tmux send-keys -t "$pane_id" "tdl ${(q)ai} ${(q)ai2}" C-m
    fi
  done
}

tsl() {
  (( $# >= 2 )) || { print -u2 "Usage: tsl <pane_count> <command>"; return 1; }
  [[ -n ${TMUX:-} ]] || { print -u2 "You must start tmux to use tsl."; return 1; }
  local count="$1" cmd="$2" current_dir="$PWD" new_pane split_target pane
  local -a panes=("$TMUX_PANE")
  tmux rename-window -t "$TMUX_PANE" "${current_dir:t}"
  while (( ${#panes} < count )); do
    split_target="${panes[-1]}"
    new_pane=$(tmux split-window -h -t "$split_target" -c "$current_dir" -P -F '#{pane_id}') || return
    panes+=("$new_pane")
    tmux select-layout -t "${panes[1]}" tiled
  done
  for pane in $panes; do tmux send-keys -t "$pane" "$cmd" C-m; done
  tmux select-pane -t "${panes[1]}"
}

# Herdr layouts
_herdr_ratio() { awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", a / b }'; }

_herdr_split() {
  herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus |
    jq -r '.result.pane.pane_id'
}

hdl() {
  [[ -n ${1:-} ]] || { print -u2 "Usage: hdl <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -n ${HERDR_PANE_ID:-} ]] || { print -u2 "You must start herdr to use hdl."; return 1; }
  local current_dir="$PWD" editor_pane="$HERDR_PANE_ID" ai_pane ai2_pane
  local ai="$1" ai2="${2:-}"
  herdr tab rename "$HERDR_TAB_ID" "${current_dir:t}" >/dev/null
  _herdr_split "$editor_pane" down 0.85 "$current_dir" >/dev/null
  ai_pane=$(_herdr_split "$editor_pane" right 0.7 "$current_dir") || return
  if [[ -n $ai2 ]]; then
    ai2_pane=$(_herdr_split "$ai_pane" down 0.5 "$current_dir") || return
    herdr pane run "$ai2_pane" "$ai2" >/dev/null
  fi
  herdr pane run "$ai_pane" "$ai" >/dev/null
  herdr pane run "$editor_pane" "$EDITOR ." >/dev/null
}

hds() {
  (( $# == 0 )) || { print -u2 "Usage: hds"; return 1; }
  [[ -n ${HERDR_PANE_ID:-} ]] || { print -u2 "You must start herdr to use hds."; return 1; }
  local current_dir="$PWD" editor_pane="$HERDR_PANE_ID" diff_pane terminal_pane opencode_pane
  herdr tab rename "$HERDR_TAB_ID" "${current_dir:t}" >/dev/null
  terminal_pane=$(_herdr_split "$editor_pane" down 0.5 "$current_dir") || return
  diff_pane=$(_herdr_split "$editor_pane" right 0.5 "$current_dir") || return
  opencode_pane=$(_herdr_split "$terminal_pane" right 0.5 "$current_dir") || return
  herdr pane run "$editor_pane" "nvim ." >/dev/null
  herdr pane run "$diff_pane" "hunk diff --watch" >/dev/null
  herdr pane run "$opencode_pane" "opencode" >/dev/null
}

hdlm() {
  [[ -n ${1:-} ]] || { print -u2 "Usage: hdlm <c|cx|codex|other_ai> [<second_ai>]"; return 1; }
  [[ -n ${HERDR_PANE_ID:-} ]] || { print -u2 "You must start herdr to use hdlm."; return 1; }
  local ai="$1" ai2="${2:-}" base_dir="$PWD" dir dirpath pane_id hdl_command
  local first=1
  herdr workspace rename "$HERDR_WORKSPACE_ID" "${base_dir:t}" >/dev/null
  for dir in "$base_dir"/*(N/); do
    dirpath="${dir%/}"
    printf -v hdl_command 'hdl %q' "$ai"
    [[ -n $ai2 ]] && printf -v hdl_command '%s %q' "$hdl_command" "$ai2"
    if (( first )); then
      printf -v hdl_command 'builtin cd %q && %s' "$dirpath" "$hdl_command"
      herdr pane run "$HERDR_PANE_ID" "$hdl_command" >/dev/null
      first=0
    else
      pane_id=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$dirpath" --no-focus |
        jq -r '.result.root_pane.pane_id') || return
      herdr pane run "$pane_id" "$hdl_command" >/dev/null
    fi
  done
}

hsl() {
  (( $# >= 2 )) || { print -u2 "Usage: hsl <pane_count> <command>"; return 1; }
  [[ -n ${HERDR_PANE_ID:-} ]] || { print -u2 "You must start herdr to use hsl."; return 1; }
  local count="$1" cmd="$2" current_dir="$PWD" cols=1 k index rows j col last pane
  local -a columns=("$HERDR_PANE_ID") panes
  herdr tab rename "$HERDR_TAB_ID" "${current_dir:t}" >/dev/null
  while (( cols * cols < count )); do (( cols++ )); done
  for (( k = 1; k < cols; k++ )); do
    columns+=("$(_herdr_split "${columns[-1]}" right "$(_herdr_ratio 1 $((cols - k + 1)))" "$current_dir")")
  done
  for (( index = 1; index <= cols; index++ )); do
    col="${columns[index]}"
    rows=$(( count / cols ))
    (( index <= count % cols )) && (( rows++ ))
    panes+=("$col")
    last="$col"
    for (( j = 1; j < rows; j++ )); do
      last=$(_herdr_split "$last" down "$(_herdr_ratio 1 $((rows - j + 1)))" "$current_dir") || return
      panes+=("$last")
    done
  done
  for pane in $panes; do herdr pane run "$pane" "$cmd" >/dev/null; done
}

# SSH wrapper and helpers
_ssh_command() {
  local ssh_term="$TERM"
  local -a ssh_opts
  if [[ -n ${GHOSTTY_RESOURCES_DIR:-} ]]; then
    ssh_term=xterm-256color
    ssh_opts=(-o 'SetEnv COLORTERM=truecolor' -o 'SendEnv TERM_PROGRAM TERM_PROGRAM_VERSION')
  fi
  TERM="$ssh_term" command ssh $ssh_opts "$@"
}

ssh() {
  local rc started=$SECONDS
  _ssh_command "$@"
  rc=$?
  [[ -t 1 ]] || return $rc
  _ssh_disarm
  if (( rc != 255 || SECONDS - started < 30 )) || [[ ! -t 0 ]] || ! _ssh_interactive "$@"; then
    return $rc
  fi
  (
    while true; do
      print "Connection lost. Reconnecting (Ctrl-C to stop)..."
      sleep 2
      _ssh_command "$@"
      rc=$?
      _ssh_disarm
      (( rc != 255 )) && return $rc
    done
  )
}

_ssh_disarm() {
  printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?1004l\e[?1049l\e[?25h'
}

_ssh_interactive() {
  local value_opts='BbcDEeFIiJLlmOoPpQRSWw' arg letters dest='' opts_done='' resolved
  local -a argv=("$@")
  local i
  while (( $# )); do
    arg="$1"
    shift
    if [[ -z $opts_done && $arg == -- ]]; then
      opts_done=1
    elif [[ -z $opts_done && $arg == -?* ]]; then
      letters="${arg#-}"
      for (( i = 1; i <= ${#letters}; i++ )); do
        if [[ $value_opts == *${letters[i]}* ]]; then
          if (( i == ${#letters} )); then
            (( $# )) || return 1
            shift
          fi
          break
        fi
      done
    elif [[ -z $dest ]]; then
      dest="$arg"
    else
      return 1
    fi
  done
  [[ -n $dest ]] || return 1
  resolved=$(command ssh -G $argv 2>/dev/null) || return 1
  ! print -r -- "$resolved" | grep -i '^remotecommand ' | grep -qvi '^remotecommand none$'
}

fip() {
  (( $# >= 2 )) || { print -u2 "Usage: fip <host> <port1> [port2] ..."; return 1; }
  local host="$1" port
  shift
  for port in "$@"; do
    ssh -f -N -L "${port}:localhost:${port}" "$host" &&
      print "Forwarding localhost:$port -> $host:$port"
  done
}

dip() {
  (( $# )) || { print -u2 "Usage: dip <port1> [port2] ..."; return 1; }
  local port
  for port in "$@"; do
    pkill -f "ssh.*-L ${port}:localhost:${port}" && print "Stopped forwarding port $port" ||
      print "No forwarding on port $port"
  done
}

lip() { pgrep -af 'ssh.*-L [0-9]+:localhost:[0-9]+' || print "No active forwards"; }

# Rsync-on-change watchers
rsw() {
  (( $# == 2 )) || { print -u2 "Usage: rsw <source> <destination>"; return 1; }
  local src="${1%/}" dest="$2" sockets="${XDG_RUNTIME_DIR:-$HOME/.ssh/sockets}" rsh
  mkdir -p "$sockets"
  rsh="ssh -o ControlMaster=auto -o ControlPath=$sockets/rsw-%r@%h:%p -o ControlPersist=yes"
  setsid --fork env RSYNC_RSH="$rsh" zsh -c \
    'rsync -a "$1/" "$2"; while inotifywait -r -q -e modify,create,delete,move "$1"; do rsync -a "$1/" "$2"; done' \
    rsw-watch "$src" "$dest" >/dev/null 2>&1
  print "Watching $src -> $dest"
}

lsw() {
  local pid cmd rest found=0
  while read -r pid cmd; do
    rest="${cmd##*rsw-watch }"
    print "$pid: ${rest% *} -> ${rest##* }"
    found=1
  done < <(pgrep -af 'rsw-watch ')
  (( found )) || print "No active watches"
}

dsw() {
  local pid found=0
  for pid in $(pgrep -f 'rsw-watch '); do
    kill -- -"$pid" 2>/dev/null && { print "Stopped watch (pid $pid)"; found=1; }
  done
  (( found )) || print "No active watches"
}

# Compression and drives
compress() { tar -czf "${1%/}.tar.gz" "${1%/}"; }

iso2sd() {
  (( $# >= 1 )) || { print -u2 "Usage: iso2sd <input_file> [output_device]"; return 1; }
  local iso="$1" drive="${2:-}" available_sds
  if [[ -z $drive ]]; then
    available_sds=$(lsblk -dpno NAME | grep -E '/dev/sd')
    [[ -n $available_sds ]] || { print -u2 "No SD drives found and no drive specified"; return 1; }
    drive=$(omarchy-drive-select "$available_sds")
    [[ -n $drive ]] || { print -u2 "No drive selected"; return 1; }
  fi
  sudo dd bs=4M status=progress oflag=sync if="$iso" of="$drive" && sudo eject "$drive"
}

format-drive() {
  if (( $# != 2 )); then
    print -u2 "Usage: format-drive <device> <name>"
    print -u2 "Example: format-drive /dev/sda 'My Stuff'"
    print -u2 "\nAvailable drives:"
    lsblk -d -o NAME -n | awk '{print "/dev/"$1}'
    return 1
  fi
  local device="$1" label="$2" confirm partition
  print "WARNING: This will completely erase all data on $device and label it '$label'."
  read -r "confirm?Are you sure you want to continue? (y/N): "
  [[ $confirm == [Yy] ]] || return
  sudo wipefs -a "$device" || return
  sudo dd if=/dev/zero of="$device" bs=1M count=100 status=progress || return
  sudo parted -s "$device" mklabel gpt || return
  sudo parted -s "$device" mkpart primary 1MiB 100% || return
  sudo parted -s "$device" set 1 msftdata on || return
  [[ $device == *nvme* ]] && partition="${device}p1" || partition="${device}1"
  sudo partprobe "$device" || true
  sudo udevadm settle || true
  sudo mkfs.exfat -n "$label" "$partition" &&
    print "Drive $device formatted as exFAT and labeled '$label'."
}
