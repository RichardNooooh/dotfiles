# Kitty Placeholder Repro

`kitty_placeholder_repro.py` is a standalone, stdlib-only reproduction of the
pinned Jupynvim Unicode-placeholder path. It reads the first valid `400x200`
`image/png` value from `fixtures/notebook-fidelity.ipynb`, then emits the same
chunked `a=t,f=100` transmission and explicit `a=p,U=1,p=1,c=48,r=ROWS`
virtual placement. Each `U+10EEEE` cell has the pinned row and column
diacritics and foreground RGB encoding a per-run nonzero image ID. The random
ID reduces collisions with other terminal clients but is not a global registry;
cleanup targets only that chosen ID.

Launch from any working directory in an interactive Kitty-compatible terminal:

```bash
python3 /home/rnoh/.dotfiles/experiments/notebooks/scripts/kitty_placeholder_repro.py
```

The default is exactly 48 columns by 16 rows. Use `--rows N` (1–297) for a
controlled height comparison; columns intentionally remain 48. The script
uses the alternate screen, rejects non-TTY graphics mode, and deletes only its
own image ID on normal exit or Ctrl-C. It changes neither terminal configuration
nor the user's main scrollback. When `TMUX` is set, graphics messages are
wrapped in the same tmux DCS passthrough form as pinned Jupynvim; enable
`allow-passthrough` only on the temporary trial tmux session before testing.

The initial draw is deliberately the base transmit-plus-placement protocol; it
does not perform Jupynvim's later asynchronous placement reassertion. Keys:
`s` scrolls only the terminal region holding placeholder text one row; `r`
re-renders the original placeholder text without a graphics command; `p` sends
Jupynvim's exact placement-only reset (`a=d,d=i` then `a=p,U=1,p=1`) without
retransmitting image data; `c` clears the text while retaining image data until
exit; `q` quits. Compare `s`, `r`, and `p` to separate terminal-region
scrolling, ordinary text re-rendering, and placement reset behavior.

For a bounded, control-free inspection that is safe to pipe and does not
require a TTY, use:

```bash
python3 /home/rnoh/.dotfiles/experiments/notebooks/scripts/kitty_placeholder_repro.py --dump | less
```

Pass criteria: in Ghostty/tmux with temporary passthrough, the image should
cover the 48x16 placeholder grid and stay aligned with the text after `s` and
`r`. In Herdr, the same result is evidence that its Kitty graphics path handles
this protocol; a missing, corrupted, or independently moving image is a repro,
not proof of a Jupynvim defect. This tool makes no visual pass claim itself.
