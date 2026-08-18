# Neovim

This package owns the Neovim configuration and is deployed with GNU Stow.

Omarchy is an optional integration provider. When present, Neovim follows its
current theme and remote clipboard behavior; otherwise the config uses a local
fallback theme.

Mason owns editor tooling for the configured first-class languages. Formatting
is repository-gated and never silently falls back to LSP formatting.

`omarchy reinstall` restores packaged Neovim defaults and can conflict with the
stowed config. Back up local work and restow this package afterward.
