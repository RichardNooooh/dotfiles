#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ( $1 != jupynvim && $1 != molten-jupytext ) ]]; then
  printf 'usage: %s {jupynvim|molten-jupytext}\n' "$0" >&2
  exit 64
fi

root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
export UV_CACHE_DIR="$root/.cache/uv"
shared_python="$root/.local/python/bin/python"
candidate=$1
mkdir -p "$root/work"
workdir=$(mktemp -d "$root/work/headless-$candidate.XXXXXX")

"$root/scripts/bootstrap.sh"
mkdir -p "$workdir/data/jupyter/runtime" "$workdir/config" "$workdir/state" "$workdir/cache" "$workdir/runtime"

run_probe() {
  local mode=$1
  local notebook=${2:-"$workdir/$mode.ipynb"}
  if [[ $# -eq 1 ]]; then
    cp "$root/fixtures/notebook-fidelity.ipynb" "$notebook"
  fi
  env \
    NOTEBOOK_EXPERIMENT_ROOT="$root" \
    NOTEBOOK_CANDIDATE="$candidate" \
    NOTEBOOK_PROBE_MODE="$mode" \
    NOTEBOOK_WORKDIR="$workdir" \
    NOTEBOOK_HEADLESS=1 \
    NOTEBOOK_SHARED_PYTHON="$shared_python" \
    JUPYTER_PATH="$root/.local/python/share/jupyter" \
    JUPYTER_RUNTIME_DIR="$workdir/runtime" \
    PATH="$root/.local/python/bin:$PATH" \
    NVIM_APPNAME="notebook-headless-$candidate" \
    XDG_CONFIG_HOME="$workdir/config" \
    XDG_DATA_HOME="$workdir/data" \
    XDG_STATE_HOME="$workdir/state" \
    XDG_CACHE_HOME="$workdir/cache" \
    nvim --headless -u "$root/candidate-configs/$candidate/init.lua" -i NONE \
    "$notebook" "+luafile $root/scripts/headless-probe.lua"
  printf '%s notebook: %s\n' "$mode" "$notebook"
}

run_probe strict
uv --directory "$root" run python -m notebook_experiment.checker \
  "$root/fixtures/notebook-fidelity.ipynb" "$workdir/strict.ipynb"

run_probe edit
uv --directory "$root" run python -c '
import copy
import json
import sys
from notebook_experiment.checker import first_difference

with open(sys.argv[1], encoding="utf-8") as file:
    baseline = json.load(file)
with open(sys.argv[2], encoding="utf-8") as file:
    candidate = json.load(file)

expected = copy.deepcopy(baseline)
cell = next(cell for cell in expected["cells"] if cell["id"] == "environment-report")
if cell["source"][0] != "import sys\n":
    raise SystemExit("baseline environment-report source no longer has the expected first line")
cell["source"].insert(1, "# notebook trial persisted edit\n")

if first_difference(expected, candidate) is not None:
    raise SystemExit(
        "persisted edit differs from the strict expected notebook semantics; "
        "only the intended environment-report source insertion is allowed"
    )
' "$root/fixtures/notebook-fidelity.ipynb" "$workdir/edit.ipynb"

run_probe execute
uv --directory "$root" run python -m notebook_experiment.checker \
  --execution-interpreter "$root/.local/python/bin/python" \
  "$root/fixtures/notebook-fidelity.ipynb" "$workdir/execute.ipynb"
run_probe reopen "$workdir/execute.ipynb"

printf 'work directory: %s\n' "$workdir"
