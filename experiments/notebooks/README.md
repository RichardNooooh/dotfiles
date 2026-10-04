# Notebook Candidate Trial

This is a disposable, synthetic-only comparison of two Neovim notebook
candidates. It does not add either plugin to normal Neovim, Ghostty, tmux, or
Herdr configuration, except for the separately approved experimental Herdr
Kitty-graphics opt-in. The fixture, launcher work copies, plugin checkouts,
kernel, remote-plugin manifest, and XDG state stay under this directory.

## Candidates and Pins

| Candidate | Pinned upstream revision | Trial role |
| --- | --- | --- |
| jupynvim | `sheng-tse/jupynvim@5e8eb2c2a6e41c722ff502360a5335dde21a634f` (v0.4.5) | Native `.ipynb` editor and kernel client |
| Molten | `benlubas/molten-nvim@bedea63819c618e007e7c40059fc6e72d598c8df` | Cell execution and outputs |
| Jupytext | `GCBallesteros/jupytext.nvim@c8baf3ad344c59b3abd461ecc17fc16ec44d0f7b` | `.ipynb` plaintext conversion/save path |
| image.nvim | `3rd/image.nvim@365e2ace0f619164ae6fd2f6f1d2807775dd6849` | Molten image backend |
| Python Tree-sitter grammar | `tree-sitter/tree-sitter-python@26855eabccb19c6abf499fbc5b8dc7cc9ab8bc64` | Project-local parser required by Molten output export |

`scripts/bootstrap.sh` installs the pinned plugins below ignored `.local/` and
creates one shared `python3` kernelspec from `.local/python`. It syncs the
fully pinned kernel runtime from `requirements.txt`, generated from the exact
direct inputs in `requirements.in`; regenerate it with `UV_CACHE_DIR=.cache/uv
uv pip compile requirements.in -o requirements.txt`. This runtime lock is
separate from `uv.lock`, which locks the test and typechecking harness used by
`uv run`. All scripts set `UV_CACHE_DIR=.cache/uv`, and the project config
applies the same local cache to `uv run` typechecking and test commands. The
direct Python inputs are: `cairosvg 2.8.2`, `ipykernel 6.30.1`,
`jupyter-client 8.6.3`, `jupytext 1.17.3`, `matplotlib 3.10.5`, `nbformat
5.10.4`, `pandas 2.3.2`, `pynvim 0.5.2`, and `ty 0.0.79`. It also uses
jupynvim's upstream release installer, which verified the v0.4.5 Linux binary
against the published `SHA256SUMS` in this trial.

## Preconditions Observed

- Neovim `0.12.5`
- Ghostty `1.3.1-arch2`
- tmux `3.7c`
- `magick` at `/usr/bin/magick`
- Herdr `0.8.2` is installed. Its experimental Kitty-graphics option is now
  set to `true` in `~/.config/herdr/config.toml`; visual behavior remains
  untested.

Ghostty meets jupynvim's documented 1.3+ graphics prerequisite. For tmux,
both jupynvim and image.nvim document `allow-passthrough`; set it only on the
temporary trial session, not in `~/.tmux.conf`:

```bash
tmux new-session -A -s notebook-trial
tmux set-option -t notebook-trial allow-passthrough on
```

## Run

Bootstrap once, or let either launcher do it:

```bash
cd /home/rnoh/.dotfiles/experiments/notebooks
./scripts/bootstrap.sh
```

In a Ghostty window, first enter the temporary tmux session above and run one
of these *inside* it. The command creates a uniquely named copy under ignored
`work/`; it never opens or writes the fixture.

```bash
./scripts/launch-jupynvim.sh
./scripts/launch-molten-jupytext.sh
```

For the requested direct Herdr UI, run either same launcher in an existing
Herdr pane. Do not start `herdr` from the launcher or from inside a Herdr
session. Jupynvim is deliberately configured for its `placeholder` renderer
with a fixed `48`-column by `10`-row diagnostic fixture, so this launcher does
not test real Kitty image rendering or propose an arbitrary aspect-ratio
solution.

Each launcher exports an isolated `NVIM_APPNAME`, all four XDG roots,
`JUPYTER_PATH`, `JUPYTER_RUNTIME_DIR`, and a PATH that selects the shared
project-local kernel environment. The Molten launcher also uses an
experiment-local remote-plugin manifest. No normal editor or desktop state is
read or written intentionally.

## Automated Check

This runs independent disposable copies for: an unedited strict JSON round
trip, a persisted code-cell edit, and an environment-report execution/save/
reopen probe. The execution assertion validates notebook output schema, the
exact `.local/python/bin/python` executable path, and the expected pandas
version before allowing only that cell's `execution_count` and `outputs` to
differ from the baseline. Any other saved mutation remains a reported failure.
The edit assertion likewise compares parsed JSON to a baseline-derived expected
notebook and permits only the intended `environment-report` source line change.
Every readiness wait is bounded to 20 seconds and fails nonzero rather than
assuming startup succeeded.

```bash
./scripts/headless-check.sh jupynvim
./scripts/headless-check.sh molten-jupytext
```

See [RESULTS.md](RESULTS.md) for observed output rather than treating candidate
design or upstream documentation as a pass claim.

## Isolated Kitty Placeholder Repro

To isolate the pinned Jupynvim Unicode-placeholder graphics protocol from
Neovim, run this in an interactive Kitty-compatible terminal from any working
directory:

```bash
python3 /home/rnoh/.dotfiles/experiments/notebooks/scripts/kitty_placeholder_repro.py
```

It uses the fixture's `400x200` PNG at exactly 48 columns by 16 rows (or
`--rows N` for a controlled height comparison), wraps graphics in tmux DCS
passthrough when `TMUX` is set, and cleans up only its own image ID. See
[`scripts/README-kitty-placeholder-repro.md`](scripts/README-kitty-placeholder-repro.md)
for keys, the non-emitting `--dump` protocol inspection, and the bounded
Ghostty/tmux and Herdr pass/fail interpretation.

## Manual Acceptance Checklist

Perform this separately for each candidate in both requested UIs. Start with a
fresh launcher copy for every run. First save without editing, quit, and run
the checker against the displayed work-copy path. A strict pass covers every
field in the synthetic fixture: cells and IDs, raw cell, metadata, attachment,
and all pre-existing outputs.

- Open, inspect, and save the copy. Confirm this passes before edits:

  ```sh
  uv --directory /home/rnoh/.dotfiles/experiments/notebooks run python -m notebook_experiment.checker /home/rnoh/.dotfiles/experiments/notebooks/fixtures/notebook-fidelity.ipynb WORK_COPY
  ```

- Make and save a small edit in code, markdown, and raw cells. Reopen and
  confirm each persisted; do not call this strict-baseline pass, because the
  intentional edit changes the JSON.
- Run every code cell, then run individual dependent cells. Confirm the
  cross-cell value is visible and inspect dataframe, stream, HTML, image, and
  error outputs.
- Run the deliberate exception and confirm its expected `ValueError`; this is
  an expected exception, not a candidate failure.
- Start the bounded 12-second cell, interrupt while it is running if timing
  permits, then restart the kernel and run an individual cell again. The
  bounded wait is deliberate so this cannot leave a runaway process.
- Do not treat `:!ty check %` as a notebook LSP integration test. It only
  launches an external checker for the current on-disk path. jupynvim's default
  setup starts its own notebook LSP process for `.ipynb` buffers; inspect its
  attached client and diagnostics in the UI. Molten + Jupytext edits a markdown
  buffer and has no cell-aware LSP in this trial. Upstream recommends adding
  quarto-nvim plus otter.nvim and activating Quarto in markdown buffers for
  cell-aware LSP; neither is installed or configured here.
- Resize and scroll the pane, switch away and back, and verify cursor/cell
  output placement remains usable.
- In Ghostty/tmux, inspect image output after temporary passthrough is enabled.
  In Herdr, record graphics behavior after the experimental opt-in; no result
  is assumed from configuration alone.
- For the current Jupynvim configuration, run `:JupynvimImageMode placeholder`,
  reopen the launcher copy, then scroll the pane and switch away and back.
  Record whether the fixed `48x10` diagnostic fixture stays usable after
  scrolling, resizing, and pane switching. This does not validate Kitty
  graphics or establish a general aspect-ratio solution.

The Jupytext path renders an `.md` companion in the disposable work directory.
That conversion design is why its raw-cell, attachment, metadata, and output
round-trip must be checked empirically, even when an unedited save passes.

## Molten UI Commands

The Molten launcher intentionally keeps mappings out of normal Neovim config.
Use these upstream commands in a launched disposable copy:

- Initialize the project kernel: `:MoltenInit python3`.
- Import existing notebook outputs: `:MoltenImportOutput`. With Jupytext, use
  the original notebook explicitly if needed:
  `:MoltenImportOutput /absolute/path/to/copy.ipynb`.
- Run the current Molten cell: `:MoltenReevaluateCell`. This requires the
  cursor to be inside a code cell already known to Molten.
- Run a selected range: select it in Visual mode, then
  `:MoltenEvaluateVisual`; the function form is
  `:call MoltenEvaluateRange(start_line, end_line)` for explicit 1-based line
  numbers.
- Save Molten's internal output state: `:MoltenSave /absolute/path/to/state.json`.
- Export outputs into the notebook: `:MoltenExportOutput! /absolute/path/to/copy.ipynb`.
- Reopen a copy and load its exported output: `:MoltenInit python3`, then
  `:MoltenImportOutput /absolute/path/to/copy.ipynb`.
- Interrupt or restart: `:MoltenInterrupt` and `:MoltenRestart`; use
  `:MoltenRestart!` to restart and delete Molten outputs.

Molten upstream's notebook guide also recommends mappings for
`:MoltenEvaluateOperator`, `:MoltenReevaluateCell`, `:MoltenEvaluateVisual`,
and `:noautocmd MoltenEnterOutput`, plus explicit import/export autocommands.
This trial has not added those convenience mappings or Quarto cell navigation,
so the commands above are the actual supported UI workflow, not implied keys.

## Browser Fallback

The project-local kernel environment includes the `jupyter` launcher but not
`jupyter_server`, `notebook`, or JupyterLab, so it cannot serve a notebook in a
browser yet. Do not install outside this experiment. To add a project-local
browser server, run this explicit command yourself (it is not run by bootstrap):

```bash
UV_CACHE_DIR=/home/rnoh/.dotfiles/experiments/notebooks/.cache/uv uv --directory /home/rnoh/.dotfiles/experiments/notebooks add jupyterlab
UV_CACHE_DIR=/home/rnoh/.dotfiles/experiments/notebooks/.cache/uv uv --directory /home/rnoh/.dotfiles/experiments/notebooks run jupyter lab --no-browser --ServerApp.root_dir=/absolute/path/to/work
```

Open the URL/token printed by JupyterLab. This is a browser fallback for a
disposable work copy, not a claim that terminal image rendering or either
Neovim candidate is equivalent to JupyterLab.
