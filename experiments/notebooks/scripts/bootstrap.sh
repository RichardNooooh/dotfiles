#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export UV_CACHE_DIR="$root/.cache/uv"
state="$root/.local"
plugins="$state/plugins"
python="$state/python/bin/python"
config="$state/nvim-config"
data="$state/nvim-data"
state_home="$state/nvim-state"
cache="$state/nvim-cache"

jupynvim_core_is_ready() {
  local core=$1
  local tag=$2
  local version

  # This is an operational startup check. The installer performs release
  # checksum verification when it downloads an artifact.
  [[ -f "$core" && -x "$core" ]] || return 1
  version=$("$core" --version 2>/dev/null) || return 1
  [[ "$version" == "jupynvim-core ${tag#v}" ]]
}

if [[ ${1:-} == "--check-jupynvim-core" ]]; then
  if [[ $# -ne 3 ]]; then
    printf 'usage: %s --check-jupynvim-core CORE TAG\n' "$0" >&2
    exit 2
  fi
  jupynvim_core_is_ready "$2" "$3"
  exit $?
fi

mkdir -p "$plugins" "$config" "$data/nvim" "$state_home" "$cache"

clone_pinned() {
  local name=$1
  local url=$2
  local revision=$3
  local destination="$plugins/$name"

  if [[ ! -d "$destination/.git" ]]; then
    git clone --no-checkout "$url" "$destination"
  fi
  git -C "$destination" fetch --depth 1 origin "$revision"
  git -C "$destination" checkout --detach "$revision"
}

clone_pinned jupynvim https://github.com/sheng-tse/jupynvim.git 5e8eb2c2a6e41c722ff502360a5335dde21a634f
clone_pinned molten-nvim https://github.com/benlubas/molten-nvim.git bedea63819c618e007e7c40059fc6e72d598c8df
clone_pinned jupytext.nvim https://github.com/GCBallesteros/jupytext.nvim.git c8baf3ad344c59b3abd461ecc17fc16ec44d0f7b
clone_pinned image.nvim https://github.com/3rd/image.nvim.git 365e2ace0f619164ae6fd2f6f1d2807775dd6849
clone_pinned tree-sitter-python https://github.com/tree-sitter/tree-sitter-python.git 26855eabccb19c6abf499fbc5b8dc7cc9ab8bc64

# MoltenExportOutput uses Neovim's Python parser to compare Jupytext code to
# notebook cells. Build it under the experiment rather than reading the user's
# normal Neovim parser directory.
mkdir -p "$state/tree-sitter/parser"
cc -shared -fPIC \
  "$plugins/tree-sitter-python/src/parser.c" \
  "$plugins/tree-sitter-python/src/scanner.c" \
  -o "$state/tree-sitter/parser/python.so"

if [[ ! -x "$python" ]]; then
  uv venv --python python3 "$state/python"
fi

uv pip sync --python "$python" "$root/requirements.txt"

"$python" -m ipykernel install --prefix "$state/python" --name python3 --display-name "Python 3 (notebook experiment)"

# Molten is a Python remote plugin. Generate its manifest inside experiment
# state so neither candidate writes to the user's normal Neovim data.
NVIM_APPNAME="notebook-bootstrap-molten" \
XDG_CONFIG_HOME="$config" \
XDG_DATA_HOME="$data" \
XDG_STATE_HOME="$state_home" \
XDG_CACHE_HOME="$cache" \
  nvim --clean --headless -i NONE \
  "+set rtp^=$plugins/molten-nvim" \
  "+let g:python3_host_prog='$python'" \
  "+let g:loaded_remote_plugins='$state/nvim-data/nvim/rplugin.vim'" \
  "+lua local ok, err = pcall(vim.cmd, 'UpdateRemotePlugins'); if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end" \
  +qa

# The jupynvim build hook obtains the release binary for the checked-out tag
# and verifies its published SHA256SUMS before use.
core="$plugins/jupynvim/core/target/release/jupynvim-core"
tag=$(git -C "$plugins/jupynvim" describe --tags --exact-match)
if ! jupynvim_core_is_ready "$core" "$tag"; then
  NOTEBOOK_EXPERIMENT_ROOT="$root" \
  NVIM_APPNAME="notebook-bootstrap-jupynvim" \
  XDG_CONFIG_HOME="$config" \
  XDG_DATA_HOME="$data" \
  XDG_STATE_HOME="$state_home" \
  XDG_CACHE_HOME="$cache" \
    nvim --headless -u NONE -i NONE \
    "+set rtp^=$plugins/jupynvim" \
    "+lua local ok, err = pcall(function() require('jupynvim.backend.install').run({ dir = vim.env.NOTEBOOK_EXPERIMENT_ROOT .. '/.local/plugins/jupynvim' }) end); if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end" \
    +qa
  if ! jupynvim_core_is_ready "$core" "$tag"; then
    printf 'jupynvim installer did not produce runnable %s\n' "$tag" >&2
    exit 1
  fi
fi
