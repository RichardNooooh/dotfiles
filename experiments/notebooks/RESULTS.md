# Observed Results

Observed on 2026-09-09 using the pinned candidates and the regenerated
synthetic fixture.

## Automated Results

These are headless observations, not visual or interactive acceptance claims.

| Candidate | Strict unedited fidelity | Persisted edit | Kernel execution, save, reopen | Status |
| --- | --- | --- | --- | --- |
| jupynvim | Passed the supplied semantic JSON checker | Passed: a real code-cell comment was present in the saved `.ipynb` | Failed before reopen: the schema-valid output reported the exact `.local/python/bin/python` checker path and pandas 2.3.2, but jupynvim also saved `environment-report.metadata.execution` IOPub timestamps | Fail: unintended saved mutation |
| Molten + Jupytext + image.nvim | Passed the supplied semantic JSON checker | Passed: parsed JSON exactly matched the baseline except for the intended `environment-report` source line | Passed: schema-valid exported output reported the exact `.local/python/bin/python` checker path and pandas 2.3.2; only `environment-report.execution_count` and `outputs` changed, then a fresh Molten state imported the saved report | Pass for these bounded headless probes |

The prior result that described Molten/Jupytext as an unqualified headless pass
was overstated. Its old check saved the generated `.md` companion while the
original `.ipynb` remained unchanged, so it could not prove adapter activity.
The new persisted-edit probe corrects that: Jupytext's write handler did update
the copied `.ipynb`. The separate Molten execution readiness failure was later
repaired; its passing execution/save/reopen result is recorded in the table.

The strict checker compares all parsed JSON values. The successful unedited
probes therefore observed no loss in cell order or IDs, raw cell, notebook or
cell metadata, markdown attachment, or pre-existing stream/display/error
outputs. This is limited to this fixture and exact revisions; it is not a
general preservation guarantee.

The strengthened execution result is intentionally not backfilled from the
earlier substring-only evidence. The jupynvim timestamp-metadata failure is
recorded as reported; it has not been normalized into an execution pass.

## User-Reported Visual Evidence

- tmux Jupynvim is now working. In Herdr 0.8.2, both Jupynvim image modes
  render distorted.
- Direct kitty rendering is cleaner, but it remains a fixed screen overlay when
  the notebook scrolls, a known plugin limitation.
- Latest standalone `48x10` placeholder-fixture evidence with the same
  `400x200` PNG: all actions worked in both Ghostty/tmux and Herdr, and the
  output appeared clearer with no earlier artifacts. This is user-reported
  visual evidence only: screenshot pixel identity and cell geometry were not
  measured, so no rendering difference is confirmed. The fixed dimensions are
  a diagnostic fixture, not an arbitrary aspect-ratio solution.
- In Herdr 0.8.2, an image became visible only after `herdr server stop` and
  then start. Reloading configuration, detaching and reattaching the client,
  and restarting Neovim were insufficient.
- Standalone Herdr actions `s`/`r`/`p`/`c` appear to work, but screenshots
  remain persistently aspect-distorted at about `420x320`. No standalone
  tearing reproduction is claimed.
- Distortion therefore reproduces without Neovim or a kernel and differs in
  tmux. Whether it is caused by Herdr or by terminal geometry/interpretation
  remains unresolved.
- The corresponding fresh Jupynvim `48x10` run, including scroll, pane resize,
  and pane switching in both requested UIs, is pending. It must be launched in
  a fresh Jupynvim process so existing cache cannot affect the observation.

## Known Gaps and Blockers

- The earlier Molten failure was a harness readiness problem, not evidence of
  a Jupytext range-selection failure: `MoltenInitPost` fired before the
  upstream runtime logged `Kernel 'python3' ... is ready`, and the initial
  request remained at `execution_count: null` with empty `chunks`. The probe
  now allows a two-second startup grace period and supplies the known
  `python3` kernel ID, then polls for real output with a bounded timeout.
  The grace period is not a kernel-readiness assertion. The repaired run passed export and imported-output
  reopening, so this is no longer an adapter blocker for this bounded fixture.
- The readiness-corrected run also exposed a configuration requirement:
  `MoltenExportOutput` requires Neovim's Python Tree-sitter parser. Bootstrap
  now builds the pinned parser under `.local/tree-sitter`, rather than reading
  the user's normal Neovim parser directory; the succeeding run verified it.
- Headless image.nvim reports it cannot query terminal size. Jupynvim now uses
  `placeholder` for every launch. Molten's headless probe disables Molten image
  rendering (`molten_image_provider=none`) so imported image outputs cannot
  require a terminal size; UI launches retain the `image.nvim` provider.
- All-cell/individual-cell UI execution, deliberate-exception inspection,
  interrupt/restart interaction, actual jupynvim LSP diagnostics, scrolling,
  resizing, and pane switching remain manual acceptance work. `:!ty check %`
  is not evidence of either candidate's notebook LSP integration. The fixture's 12-second
  interrupt cell is explicitly manual-only and skipped by automation.
