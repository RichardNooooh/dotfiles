#!/usr/bin/env zsh
emulate -L zsh
setopt ERR_EXIT NO_UNSET PIPE_FAIL

data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
typeset -A repositories=(
  oh-my-zsh https://github.com/ohmyzsh/ohmyzsh.git
  plugins/fzf-tab https://github.com/Aloxaf/fzf-tab.git
)

mkdir -p "$data_dir/plugins"
for target url in ${(kv)repositories}; do
  destination="$data_dir/$target"
  if [[ -e $destination && ! -d $destination/.git ]]; then
    print -u2 "Refusing to replace non-Git path: $destination"
    return 1
  fi

  if [[ ! -d $destination/.git ]]; then
    git clone --filter=blob:none --depth=1 "$url" "$destination"
  else
    git -C "$destination" fetch --prune origin
    branch=$(git -C "$destination" symbolic-ref --quiet --short HEAD) || {
      print -u2 "Refusing to update detached repository: $destination"
      return 1
    }
    git -C "$destination" merge --ff-only "origin/$branch"
  fi
done

print "Zsh user plugins are ready under $data_dir"
print "Arch prerequisites: zsh starship fzf zsh-autosuggestions zsh-syntax-highlighting"
