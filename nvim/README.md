# Neovim

This package owns the Neovim configuration and is deployed with GNU Stow.

Omarchy is an optional integration provider. When present, Neovim follows its
current theme and remote clipboard behavior; otherwise the config uses a local
fallback theme.

Mason owns editor tooling for the configured first-class languages. Formatting
is repository-gated and never silently falls back to LSP formatting.

## Odin

Odin is installed by mise from `mise/.config/mise/conf.d/50-personal.toml` as the
latest monthly `dev-*` Linux AMD64 release. Run `mise upgrade odin` to update it;
mise continues to enforce the existing five-day minimum release age.
Mason installs `ols`, which also provides `odinfmt`, and Treesitter installs the
`odin` parser. `ols` uses its bundled root detection, which invokes `odin root`,
so Neovim must inherit the existing mise shell environment.

Odin save and manual formatting are enabled only for `.odin` files inside a Git
repository when `odinfmt.json` exists in the file's directory or an ancestor up
to the Git root, and `odinfmt` is executable. Formatting remains disabled when
any of those conditions is missing.

`omarchy reinstall` restores packaged Neovim defaults and can conflict with the
stowed config. Back up local work and restow this package afterward.
