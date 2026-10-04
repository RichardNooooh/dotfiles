#!/usr/bin/env bash
set -euo pipefail

root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export UV_CACHE_DIR="$root/.cache/uv"
source_notebook=${1:-"$root/fixtures/notebook-fidelity.ipynb"}
mkdir -p "$root/work"
workdir=$(mktemp -d "$root/work/jupynvim.XXXXXX")
trial_id=${workdir##*/}

"$root/scripts/bootstrap.sh"
mkdir -p "$workdir/data/jupyter/runtime" "$workdir/config" "$workdir/state" "$workdir/cache" "$workdir/runtime"
cp "$source_notebook" "$workdir/notebook.ipynb"

printf 'Disposable notebook: %s\n' "$workdir/notebook.ipynb"
exec env \
  NOTEBOOK_EXPERIMENT_ROOT="$root" \
  JUPYTER_PATH="$root/.local/python/share/jupyter" \
  JUPYTER_RUNTIME_DIR="$workdir/runtime" \
  PATH="$root/.local/python/bin:$PATH" \
  NVIM_APPNAME="notebook-trial-$trial_id" \
  XDG_CONFIG_HOME="$workdir/config" \
  XDG_DATA_HOME="$workdir/data" \
  XDG_STATE_HOME="$workdir/state" \
  XDG_CACHE_HOME="$workdir/cache" \
  nvim -u "$root/candidate-configs/jupynvim/init.lua" -i NONE "$workdir/notebook.ipynb"
